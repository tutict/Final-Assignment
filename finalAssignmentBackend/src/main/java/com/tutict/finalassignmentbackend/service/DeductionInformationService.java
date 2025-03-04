package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.mapper.DeductionInformationMapper;
import com.tutict.finalassignmentbackend.entity.DeductionInformation;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.logging.Logger;

@Service
public class DeductionInformationService {

    private static final Logger log = Logger.getLogger(DeductionInformationService.class.getName());

    private final DeductionInformationMapper deductionInformationMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, DeductionInformation> kafkaTemplate;

    @Autowired
    public DeductionInformationService(DeductionInformationMapper deductionInformationMapper,
                                       RequestHistoryMapper requestHistoryMapper,
                                       KafkaTemplate<String, DeductionInformation> kafkaTemplate) {
        this.deductionInformationMapper = deductionInformationMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "deductionCache", allEntries = true)
    @WsAction(service = "DeductionService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, DeductionInformation deductionInformation, String action) {
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

        sendKafkaMessage("deduction_" + action, deductionInformation);

        Integer deductionId = deductionInformation.getDeductionId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(deductionId != null ? deductionId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "deductionCache", allEntries = true)
    public void createDeduction(DeductionInformation deduction) {
        DeductionInformation existingDeduction = deductionInformationMapper.selectById(deduction.getDeductionId());
        if (existingDeduction == null) {
            deductionInformationMapper.insert(deduction);
        } else {
            deductionInformationMapper.updateById(deduction);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "deductionCache", allEntries = true)
    public void updateDeduction(DeductionInformation deduction) {
        DeductionInformation existingDeduction = deductionInformationMapper.selectById(deduction.getDeductionId());
        if (existingDeduction == null) {
            deductionInformationMapper.insert(deduction);
        } else {
            deductionInformationMapper.updateById(deduction);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "deductionCache", allEntries = true)
    @WsAction(service = "DeductionInformationService", action = "deleteDeduction")
    public void deleteDeduction(int deductionId) {
        if (deductionId <= 0) {
            throw new IllegalArgumentException("Invalid deduction ID");
        }
        int result = deductionInformationMapper.deleteById(deductionId);
        if (result > 0) {
            log.info(String.format("Deduction with ID %s deleted successfully", deductionId));
        } else {
            log.severe(String.format("Failed to delete deduction with ID %s", deductionId));
        }
    }

    @Cacheable(cacheNames = "deductionCache")
    @WsAction(service = "DeductionInformationService", action = "getDeductionById")
    public DeductionInformation getDeductionById(Integer deductionId) {
        if (deductionId == null || deductionId <= 0 || deductionId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid deduction ID " + deductionId);
        }
        return deductionInformationMapper.selectById(deductionId);
    }

    @Cacheable(cacheNames = "deductionCache")
    @WsAction(service = "DeductionInformationService", action = "getAllDeductions")
    public List<DeductionInformation> getAllDeductions() {
        return deductionInformationMapper.selectList(null);
    }

    @Cacheable(cacheNames = "deductionCache")
    @WsAction(service = "DeductionInformationService", action = "getDeductionsByHandler")
    public List<DeductionInformation> getDeductionsByHandler(String handler) {
        if (handler == null || handler.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid handler");
        }
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("handler", handler);
        return deductionInformationMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "deductionCache")
    @WsAction(service = "DeductionInformationService", action = "getDeductionsByTimeRange")
    public List<DeductionInformation> getDeductionsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("deduction_time", startTime, endTime);
        return deductionInformationMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(String topic, DeductionInformation deductionInformation) {
        kafkaTemplate.send(topic, deductionInformation);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}