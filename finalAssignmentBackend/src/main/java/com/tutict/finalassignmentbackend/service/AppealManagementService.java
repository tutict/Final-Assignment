package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.mapper.AppealManagementMapper;
import com.tutict.finalassignmentbackend.mapper.OffenseInformationMapper;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.logging.Logger;

// 申诉管理服务类
@Service
@EnableKafka
public class AppealManagementService {

    private static final Logger log = Logger.getLogger(AppealManagementService.class.getName());

    private final AppealManagementMapper appealManagementMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final OffenseInformationMapper offenseInformationMapper;
    private final KafkaTemplate<String, AppealManagement> kafkaTemplate;

    @Autowired
    public AppealManagementService(AppealManagementMapper appealManagementMapper,
                                   RequestHistoryMapper requestHistoryMapper,
                                   OffenseInformationMapper offenseInformationMapper,
                                   KafkaTemplate<String, AppealManagement> kafkaTemplate) {
        this.appealManagementMapper = appealManagementMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.offenseInformationMapper = offenseInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "appealCache", allEntries = true)
    public void checkAndInsertIdempotency(String idempotencyKey, AppealManagement appealManagement, String action) {
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
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        sendKafkaMessage("appeal_processed_" + action, appealManagement);

        Integer appealId = appealManagement.getAppealId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(appealId);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "appealCache", allEntries = true)
    public void createAppeal(AppealManagement appeal) {
        AppealManagement existingAppeal = appealManagementMapper.selectById(appeal.getAppealId());
        if (existingAppeal == null) {
            appealManagementMapper.insert(appeal);
        } else {
            appealManagementMapper.updateById(appeal);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "appealCache", allEntries = true)
    public void updateAppeal(AppealManagement appeal) {
        AppealManagement existingAppeal = appealManagementMapper.selectById(appeal.getAppealId());
        if (existingAppeal == null) {
            appealManagementMapper.insert(appeal);
        } else {
            appealManagementMapper.updateById(appeal);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "appealCache", allEntries = true)
    public void deleteAppeal(Integer appealId) {
        if (appealId == null || appealId <= 0) {
            throw new IllegalArgumentException("Invalid appeal ID");
        }
        int result = appealManagementMapper.deleteById(appealId);
        if (result > 0) {
            log.info(String.format("Appeal with ID %s deleted successfully", appealId));
        } else {
            log.severe(String.format("Failed to delete appeal with ID %s", appealId));
        }
    }

    @Cacheable(cacheNames = "appealCache")
    public AppealManagement getAppealById(Integer appealId) {
        if (appealId == null || appealId <= 0 || appealId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Appeal not found for ID: " + appealId);
        }
        return appealManagementMapper.selectById(appealId);
    }

    @Cacheable(cacheNames = "appealCache")
    public List<AppealManagement> getAllAppeals() {
        return appealManagementMapper.selectList(null);
    }

    @Cacheable(cacheNames = "appealCache")
    public List<AppealManagement> getAppealsByProcessStatus(String processStatus) {
        if (processStatus == null || processStatus.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid process status");
        }
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processStatus);
        return appealManagementMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "appealCache")
    public List<AppealManagement> getAppealsByAppealName(String appealName) {
        if (appealName == null || appealName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid appeal name");
        }
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("appeal_name", appealName);
        return appealManagementMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "appealCache")
    public OffenseInformation getOffenseByAppealId(Integer appealId) {
        AppealManagement appeal = appealManagementMapper.selectById(appealId);
        if (appeal != null) {
            return offenseInformationMapper.selectById(appeal.getOffenseId());
        } else {
            log.warning(String.format("No appeal found with ID: %s", appealId));
            return null;
        }
    }

    private void sendKafkaMessage(String topic, AppealManagement appeal) {
        kafkaTemplate.send(topic, appeal);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}