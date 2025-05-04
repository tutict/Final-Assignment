package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.OperationLogDocument;
import com.tutict.finalassignmentbackend.mapper.OperationLogMapper;
import com.tutict.finalassignmentbackend.entity.OperationLog;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.OperationLogSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Service
public class OperationLogService {

    private static final Logger log = Logger.getLogger(OperationLogService.class.getName());

    private final OperationLogMapper operationLogMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final OperationLogSearchRepository operationLogSearchRepository;
    private final KafkaTemplate<String, OperationLog> kafkaTemplate;

    @Autowired
    public OperationLogService(OperationLogMapper operationLogMapper,
                               RequestHistoryMapper requestHistoryMapper,
                               OperationLogSearchRepository operationLogSearchRepository,
                               KafkaTemplate<String, OperationLog> kafkaTemplate) {
        this.operationLogMapper = operationLogMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.operationLogSearchRepository = operationLogSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "operationCache", allEntries = true)
    @WsAction(service = "OperationLogService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, OperationLog operationLog, String action) {
        // 查询 request_history
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            log.warning(String.format("Duplicate request detected (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate request detected");
        }

        // 不存在 -> 插入一条 PROCESSING
        RequestHistory newRequest = new RequestHistory();
        newRequest.setIdempotentKey(idempotencyKey);
        newRequest.setBusinessStatus("PROCESSING");

        try {
            requestHistoryMapper.insert(newRequest);
        } catch (Exception e) {
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        sendKafkaMessage("operation_" + action, operationLog);

        Integer operationId = operationLog.getLogId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(operationId != null ? operationId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "operationCache", allEntries = true)
    public void createOperationLog(OperationLog operationLog) {
        OperationLog existingLog = operationLogMapper.selectById(operationLog.getLogId());
        if (existingLog == null) {
            operationLogMapper.insert(operationLog);
        } else {
            operationLogMapper.updateById(operationLog);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "operationCache", allEntries = true)
    public void updateOperationLog(OperationLog operationLog) {
        OperationLog existingLog = operationLogMapper.selectById(operationLog.getLogId());
        if (existingLog == null) {
            operationLogMapper.insert(operationLog);
        } else {
            operationLogMapper.updateById(operationLog);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "operationCache", allEntries = true)
    @WsAction(service = "OperationLogService", action = "deleteOperationLog")
    public void deleteOperationLog(int logId) {
        if (logId <= 0) {
            throw new IllegalArgumentException("Invalid log ID");
        }
        int result = operationLogMapper.deleteById(logId);
        if (result > 0) {
            log.info(String.format("Operation log with ID %s deleted successfully", logId));
        } else {
            log.severe(String.format("Failed to delete operation log with ID %s", logId));
        }
    }

    @Cacheable(cacheNames = "operationCache")
    @WsAction(service = "OperationLogService", action = "getOperationLog")
    public OperationLog getOperationLog(Integer logId) {
        if (logId == null || logId <= 0 || logId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid log ID" + logId);
        }
        return operationLogMapper.selectById(logId);
    }

    @Cacheable(cacheNames = "operationCache")
    @WsAction(service = "OperationLogService", action = "getAllOperationLogs")
    public List<OperationLog> getAllOperationLogs() {
        return operationLogMapper.selectList(null);
    }

    @Cacheable(cacheNames = "operationCache")
    @WsAction(service = "OperationLogService", action = "getOperationLogsByTimeRange")
    public List<OperationLog> getOperationLogsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("operation_time", startTime, endTime);
        return operationLogMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "operationCache")
    @WsAction(service = "OperationLogService", action = "getOperationLogsByUserId")
    public List<OperationLog> getOperationLogsByUserId(String userId) {
        if (userId == null || userId.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid userId");
        }
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_id", userId);
        return operationLogMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "operationCache")
    @WsAction(service = "OperationLogService", action = "getOperationLogsByResult")
    public List<OperationLog> getOperationLogsByResult(String operationResult) {
        if (operationResult == null || operationResult.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid operation result");
        }
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("operation_result", operationResult);
        return operationLogMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "operationLogCache", unless = "#result.isEmpty()")
    public List<String> getUserIdsByPrefixGlobally(String prefix) {
        validateInput(prefix, "Invalid user ID prefix");
        log.log(Level.INFO, "Fetching user ID suggestions for prefix: {0}", new Object[]{prefix});

        try {
            // Convert prefix to Integer for userId search
            int userId;
            try {
                userId = Integer.parseInt(prefix);
            } catch (NumberFormatException e) {
                log.log(Level.WARNING, "Invalid user ID format for prefix {0}: {1}", new Object[]{prefix, e.getMessage()});
                return Collections.emptyList();
            }

            SearchHits<OperationLogDocument> searchHits = operationLogSearchRepository
                    .searchByUserIdGlobally(userId);
            List<String> suggestions = searchHits.getSearchHits().stream()
                    .map(SearchHit::getContent)
                    .map(OperationLogDocument::getUserId)
                    .filter(Objects::nonNull)
                    .map(String::valueOf) // Convert Integer to String
                    .distinct()
                    .limit(10)
                    .collect(Collectors.toList());

            log.log(Level.INFO, "Found {0} user ID suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), prefix});
            return suggestions.isEmpty() ? Collections.emptyList() : suggestions;
        } catch (Exception e) {
            log.log(Level.WARNING, "Error fetching user ID suggestions for prefix {0}: {1}",
                    new Object[]{prefix, e.getMessage()});
            return Collections.emptyList();
        }
    }

    @Cacheable(cacheNames = "operationLogCache", unless = "#result.isEmpty()")
    public List<String> getOperationResultsByPrefixGlobally(String prefix) {
        validateInput(prefix, "Invalid operation result prefix");
        log.log(Level.INFO, "Fetching operation result suggestions for prefix: {0}", new Object[]{prefix});

        try {
            SearchHits<OperationLogDocument> searchHits = operationLogSearchRepository
                    .searchByOperationResultFuzzyGlobally(prefix);
            List<String> suggestions = searchHits.getSearchHits().stream()
                    .map(SearchHit::getContent)
                    .map(OperationLogDocument::getOperationResult)
                    .filter(Objects::nonNull)
                    .distinct()
                    .limit(10)
                    .collect(Collectors.toList());

            log.log(Level.INFO, "Found {0} operation result suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), prefix});
            return suggestions.isEmpty() ? Collections.emptyList() : suggestions;
        } catch (Exception e) {
            log.log(Level.WARNING, "Error fetching operation result suggestions for prefix {0}: {1}",
                    new Object[]{prefix, e.getMessage()});
            return Collections.emptyList();
        }
    }

    private void validateInput(String input, String errorMessage) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMessage);
        }
    }

    private void sendKafkaMessage(String topic, OperationLog operationLog) {
        kafkaTemplate.send(topic, operationLog);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}