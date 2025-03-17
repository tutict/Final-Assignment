package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.AppealManagementDocument;
import com.tutict.finalassignmentbackend.mapper.AppealManagementMapper;
import com.tutict.finalassignmentbackend.mapper.OffenseInformationMapper;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.AppealManagementSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

// 申诉管理服务类
@Service
public class AppealManagementService {

    private static final Logger log = Logger.getLogger(AppealManagementService.class.getName());

    private final AppealManagementMapper appealManagementMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final OffenseInformationMapper offenseInformationMapper;
    private final KafkaTemplate<String, AppealManagement> kafkaTemplate;
    private final AppealManagementSearchRepository appealManagementSearchRepository;

    @Autowired
    public AppealManagementService(
            AppealManagementMapper appealManagementMapper,
            RequestHistoryMapper requestHistoryMapper,
            OffenseInformationMapper offenseInformationMapper,
            KafkaTemplate<String, AppealManagement> kafkaTemplate,
            AppealManagementSearchRepository appealManagementSearchRepository) {
        this.appealManagementMapper = appealManagementMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.offenseInformationMapper = offenseInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
        this.appealManagementSearchRepository = appealManagementSearchRepository;
    }

    @Transactional
    @CacheEvict(cacheNames = "appealCache", allEntries = true)
    @WsAction(service = "AppealManagementService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, AppealManagement appealManagement, String action) {
        validateInput(idempotencyKey, "Idempotency key cannot be null or empty");
        if (appealManagement == null) {
            throw new IllegalArgumentException("AppealManagement cannot be null");
        }

        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            log.warning(String.format("Duplicate request detected (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate request detected");
        }

        RequestHistory newRequest = new RequestHistory();
        newRequest.setIdempotentKey(idempotencyKey);
        newRequest.setBusinessStatus("PROCESSING");

        try {
            requestHistoryMapper.insert(newRequest);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ": " + e.getMessage(), e);
            throw new RuntimeException("Failed to insert request history", e);
        }

        sendKafkaMessage(appealManagement, action);

        Integer appealId = appealManagement.getAppealId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(appealId != null ? appealId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "appealCache", allEntries = true)
    public AppealManagement createAppeal(AppealManagement appeal) {
        validateInput(appeal.getAppellantName(), "Appellant name cannot be null or empty");
        validateInput(appeal.getAppealReason(), "Appeal reason cannot be null or empty");
        if (appeal.getOffenseId() == null || appeal.getOffenseId() <= 0) {
            throw new IllegalArgumentException("Invalid offense ID");
        }

        try {
            appealManagementMapper.insert(appeal);
            appealManagementSearchRepository.save(AppealManagementDocument.fromEntity(appeal));
            log.info(String.format("Appeal created successfully, appealId=%d", appeal.getAppealId()));
            return appeal;
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to create appeal: " + e.getMessage(), e);
            throw new RuntimeException("Failed to create appeal", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "appealCache", allEntries = true)
    public AppealManagement updateAppeal(AppealManagement appeal) {
        if (appeal.getAppealId() == null || appeal.getAppealId() <= 0) {
            throw new IllegalArgumentException("Appeal ID cannot be null or invalid");
        }
        validateInput(appeal.getAppellantName(), "Appellant name cannot be null or empty");
        validateInput(appeal.getAppealReason(), "Appeal reason cannot be null or empty");

        try {
            int rowsAffected = appealManagementMapper.updateById(appeal);
            if (rowsAffected == 0) {
                log.warning("No appeal found to update for ID: " + appeal.getAppealId());
                throw new RuntimeException("Appeal not found");
            }
            appealManagementSearchRepository.save(AppealManagementDocument.fromEntity(appeal));
            log.info(String.format("Appeal updated successfully, appealId=%d", appeal.getAppealId()));
            return appeal;
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to update appeal: " + e.getMessage(), e);
            throw new RuntimeException("Failed to update appeal", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "appealCache", allEntries = true)
    @WsAction(service = "AppealManagementService", action = "deleteAppeal")
    public void deleteAppeal(Integer appealId) {
        if (appealId == null || appealId <= 0) {
            throw new IllegalArgumentException("Invalid appeal ID: " + appealId);
        }
        try {
            int rowsAffected = appealManagementMapper.deleteById(appealId);
            if (rowsAffected == 0) {
                log.warning("No appeal found to delete for ID: " + appealId);
                throw new RuntimeException("Appeal not found");
            }
            appealManagementSearchRepository.deleteById(appealId);
            log.info(String.format("Appeal with ID %d deleted successfully from both DB and Elasticsearch", appealId));
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to delete appeal: " + e.getMessage(), e);
            throw new RuntimeException("Failed to delete appeal", e);
        }
    }

    @Cacheable(cacheNames = "appealCache", unless = "#result == null")
    @WsAction(service = "AppealManagementService", action = "getAppealById")
    public AppealManagement getAppealById(Integer appealId) {
        if (appealId == null || appealId <= 0 || appealId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid appeal ID: " + appealId);
        }
        AppealManagement appeal = appealManagementMapper.selectById(appealId);
        if (appeal == null) {
            log.info("Appeal not found for ID: " + appealId);
        }
        return appeal;
    }

    @Cacheable(cacheNames = "appealCache")
    @WsAction(service = "AppealManagementService", action = "getAllAppeals")
    public List<AppealManagement> getAllAppeals() {
        List<AppealManagement> result = appealManagementMapper.selectList(null);
        return result != null ? result : Collections.emptyList();
    }

    @Cacheable(cacheNames = "appealCache")
    @WsAction(service = "AppealManagementService", action = "getAppealsByProcessStatus")
    public List<AppealManagement> getAppealsByProcessStatus(String processStatus) {
        validateInput(processStatus, "Invalid process status");
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processStatus);
        List<AppealManagement> result = appealManagementMapper.selectList(queryWrapper);
        return result != null ? result : Collections.emptyList();
    }

    @Cacheable(cacheNames = "appealCache")
    @WsAction(service = "AppealManagementService", action = "getAppealsByAppellantName")
    public List<AppealManagement> getAppealsByAppellantName(String appellantName) {
        validateInput(appellantName, "Invalid appellant name");
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("appellant_name", appellantName);
        List<AppealManagement> result = appealManagementMapper.selectList(queryWrapper);
        return result != null ? result : Collections.emptyList();
    }

    @Cacheable(cacheNames = "appealCache")
    @WsAction(service = "AppealManagementService", action = "getAppealsByIdCardNumber")
    public List<AppealManagement> getAppealsByIdCardNumber(String idCardNumber) {
        validateInput(idCardNumber, "Invalid ID card number");
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("id_card_number", idCardNumber);
        List<AppealManagement> result = appealManagementMapper.selectList(queryWrapper);
        return result != null ? result : Collections.emptyList();
    }

    @Cacheable(cacheNames = "appealCache")
    @WsAction(service = "AppealManagementService", action = "getAppealsByContactNumber")
    public List<AppealManagement> getAppealsByContactNumber(String contactNumber) {
        validateInput(contactNumber, "Invalid contact number");
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("contact_number", contactNumber);
        List<AppealManagement> result = appealManagementMapper.selectList(queryWrapper);
        return result != null ? result : Collections.emptyList();
    }

    @Cacheable(cacheNames = "appealCache")
    @WsAction(service = "AppealManagementService", action = "getAppealsByOffenseId")
    public List<AppealManagement> getAppealsByOffenseId(Integer offenseId) {
        if (offenseId == null || offenseId <= 0) {
            throw new IllegalArgumentException("Invalid offense ID: " + offenseId);
        }
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("offense_id", offenseId);
        List<AppealManagement> result = appealManagementMapper.selectList(queryWrapper);
        return result != null ? result : Collections.emptyList();
    }

    @Cacheable(cacheNames = "appealCache")
    @WsAction(service = "AppealManagementService", action = "getOffenseByAppealId")
    public OffenseInformation getOffenseByAppealId(Integer appealId) {
        if (appealId == null || appealId <= 0) {
            throw new IllegalArgumentException("Invalid appeal ID: " + appealId);
        }
        AppealManagement appeal = appealManagementMapper.selectById(appealId);
        if (appeal != null && appeal.getOffenseId() != null) {
            return offenseInformationMapper.selectById(appeal.getOffenseId());
        } else {
            log.warning(String.format("No appeal or offense found for appeal ID: %s", appealId));
            return null;
        }
    }

    @Cacheable(cacheNames = "appealCache")
    @WsAction(service = "AppealManagementService", action = "getAppealsByAppealTimeBetween")
    public List<AppealManagement> getAppealsByAppealTimeBetween(LocalDateTime startTime, LocalDateTime endTime) {
        if (startTime == null || endTime == null || startTime.isAfter(endTime)) {
            throw new IllegalArgumentException("Invalid time range: startTime=" + startTime + ", endTime=" + endTime);
        }
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("appeal_time", startTime, endTime);
        List<AppealManagement> result = appealManagementMapper.selectList(queryWrapper);
        return result != null ? result : Collections.emptyList();
    }

    @Cacheable(cacheNames = "appealCache")
    @WsAction(service = "AppealManagementService", action = "getAppealsByReasonContaining")
    public List<AppealManagement> getAppealsByReasonContaining(String reason) {
        validateInput(reason, "Invalid appeal reason");
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("appeal_reason", reason);
        List<AppealManagement> result = appealManagementMapper.selectList(queryWrapper);
        return result != null ? result : Collections.emptyList();
    }

    @Cacheable(cacheNames = "appealCache")
    @WsAction(service = "AppealManagementService", action = "getAppealsByStatusAndTime")
    public List<AppealManagement> getAppealsByStatusAndTime(String processStatus, LocalDateTime startTime, LocalDateTime endTime) {
        validateInput(processStatus, "Invalid process status");
        if (startTime == null || endTime == null || startTime.isAfter(endTime)) {
            throw new IllegalArgumentException("Invalid time range: startTime=" + startTime + ", endTime=" + endTime);
        }
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processStatus)
                .between("appeal_time", startTime, endTime);
        List<AppealManagement> result = appealManagementMapper.selectList(queryWrapper);
        return result != null ? result : Collections.emptyList();
    }

    @Cacheable(cacheNames = "appealCache")
    @WsAction(service = "AppealManagementService", action = "countAppealsByStatus")
    public long countAppealsByStatus(String processStatus) {
        validateInput(processStatus, "Invalid process status");
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processStatus);
        return appealManagementMapper.selectCount(queryWrapper);
    }

    public List<AppealManagement> searchAppeals(String query, int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
        try {
            Page<AppealManagementDocument> results = appealManagementSearchRepository
                    .findByAppellantNameContainingOrAppealReasonContainingOrProcessStatusContaining(
                            query, PageRequest.of(page - 1, size));
            List<AppealManagement> appeals = results.getContent().stream()
                    .map(AppealManagementDocument::toEntity)
                    .collect(Collectors.toList());
            log.info("Search completed for query '" + query + "' with " + appeals.size() + " results");
            return appeals;
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to search appeals: " + e.getMessage(), e);
            return Collections.emptyList();
        }
    }

    private void sendKafkaMessage(AppealManagement appeal, String action) {
        if (appeal == null || action == null) {
            log.warning("Cannot send Kafka message with null appeal or action");
            return;
        }
        String topic = "appeal_" + action.toLowerCase();
        try {
            kafkaTemplate.send(topic, appeal);
            log.info(String.format("Message sent to Kafka topic %s successfully", topic));
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to send Kafka message to topic " + topic + ": " + e.getMessage(), e);
        }
    }

    private void validateInput(String input, String errorMessage) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMessage);
        }
    }
}