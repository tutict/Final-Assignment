package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.SystemLogsDocument;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.SystemLogsMapper;
import com.tutict.finalassignmentbackend.entity.SystemLogs;
import com.tutict.finalassignmentbackend.repository.SystemLogsSearchRepository;
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
public class SystemLogsService {

    private static final Logger log = Logger.getLogger(SystemLogsService.class.getName());

    private final SystemLogsMapper systemLogsMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, SystemLogs> kafkaTemplate;
    private final SystemLogsSearchRepository systemLogsSearchRepository;


    @Autowired
    public SystemLogsService(SystemLogsMapper systemLogsMapper,
                             RequestHistoryMapper requestHistoryMapper,
                             SystemLogsSearchRepository systemLogsSearchRepository,
                             KafkaTemplate<String, SystemLogs> kafkaTemplate) {
        this.systemLogsMapper = systemLogsMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.systemLogsSearchRepository = systemLogsSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "systemLogCache", allEntries = true)
    @WsAction(service = "SystemLogsService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SystemLogs systemLogs, String action) {
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

        sendKafkaMessage("system_" + action, systemLogs);

        Integer systemLogsId = systemLogs.getLogId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(systemLogsId != null ? systemLogsId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "systemLogCache", allEntries = true)
    public void createSystemLog(SystemLogs systemLog) {
        systemLogsMapper.insert(systemLog);
    }

    @Transactional
    @CacheEvict(cacheNames = "systemLogCache", allEntries = true)
    public void updateSystemLog(SystemLogs systemLog) {
        SystemLogs existingLog = systemLogsMapper.selectById(systemLog.getLogId());
        if (existingLog != null) {
            systemLogsMapper.updateById(systemLog);
        } else {
            log.warning(String.format("System log with ID %d not found. Cannot update.", systemLog.getLogId()));
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "systemLogCache", allEntries = true)
    @WsAction(service = "SystemLogsService", action = "deleteSystemLog")
    public void deleteSystemLog(int logId) {
        if (logId <= 0) {
            throw new IllegalArgumentException("Invalid log ID");
        }
        SystemLogs systemLogToDelete = systemLogsMapper.selectById(logId);
        if (systemLogToDelete != null) {
            systemLogsMapper.deleteById(logId);
            log.info(String.format("System log with ID %d deleted successfully", logId));
        } else {
            log.warning(String.format("System log with ID %d not found. Cannot delete.", logId));
        }
    }

    @Cacheable(cacheNames = "systemLogCache")
    @WsAction(service = "SystemLogsService", action = "getSystemLogById")
    public SystemLogs getSystemLogById(Integer logId) {
        if (logId == null || logId <= 0 || logId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid log ID" + logId);
        }
        return systemLogsMapper.selectById(logId);
    }

    @Cacheable(cacheNames = "systemLogCache")
    @WsAction(service = "SystemLogsService", action = "getAllSystemLogs")
    public List<SystemLogs> getAllSystemLogs() {
        return systemLogsMapper.selectList(null);
    }

    @Cacheable(cacheNames = "systemLogCache")
    @WsAction(service = "SystemLogsService", action = "getSystemLogsByType")
    public List<SystemLogs> getSystemLogsByType(String logType) {
        if (logType == null || logType.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid log type");
        }
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("log_type", logType);
        return systemLogsMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "systemLogCache")
    @WsAction(service = "SystemLogsService", action = "getSystemLogsByTimeRange")
    public List<SystemLogs> getSystemLogsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("operation_time", startTime, endTime);
        return systemLogsMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "systemLogCache")
    @WsAction(service = "SystemLogsService", action = "getSystemLogsByOperationUser")
    public List<SystemLogs> getSystemLogsByOperationUser(String operationUser) {
        if (operationUser == null || operationUser.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid operation user");
        }
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("operation_user", operationUser);
        return systemLogsMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "systemLogsCache", unless = "#result.isEmpty()")
    public List<String> getLogTypesByPrefixGlobally(String prefix) {
        validateInput(prefix, "Invalid log type prefix");
        log.log(Level.INFO, "Fetching log type suggestions for prefix: {0}", new Object[]{prefix});

        try {
            SearchHits<SystemLogsDocument> searchHits = systemLogsSearchRepository
                    .searchByLogTypeFuzzyGlobally(prefix);
            List<String> suggestions = searchHits.getSearchHits().stream()
                    .map(SearchHit::getContent)
                    .map(SystemLogsDocument::getLogType)
                    .filter(Objects::nonNull)
                    .distinct()
                    .limit(10)
                    .collect(Collectors.toList());

            log.log(Level.INFO, "Found {0} log type suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), prefix});
            return suggestions.isEmpty() ? Collections.emptyList() : suggestions;
        } catch (Exception e) {
            log.log(Level.WARNING, "Error fetching log type suggestions for prefix {0}: {1}",
                    new Object[]{prefix, e.getMessage()});
            return Collections.emptyList();
        }
    }

    @Cacheable(cacheNames = "systemLogsCache", unless = "#result.isEmpty()")
    public List<String> getOperationUsersByPrefixGlobally(String prefix) {
        validateInput(prefix, "Invalid operation user prefix");
        log.log(Level.INFO, "Fetching operation user suggestions for prefix: {0}", new Object[]{prefix});

        try {
            SearchHits<SystemLogsDocument> searchHits = systemLogsSearchRepository
                    .searchByOperationUserGlobally(prefix);
            List<String> suggestions = searchHits.getSearchHits().stream()
                    .map(SearchHit::getContent)
                    .map(SystemLogsDocument::getOperationUser)
                    .filter(Objects::nonNull)
                    .distinct()
                    .limit(10)
                    .collect(Collectors.toList());

            log.log(Level.INFO, "Found {0} operation user suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), prefix});
            return suggestions.isEmpty() ? Collections.emptyList() : suggestions;
        } catch (Exception e) {
            log.log(Level.WARNING, "Error fetching operation user suggestions for prefix {0}: {1}",
                    new Object[]{prefix, e.getMessage()});
            return Collections.emptyList();
        }
    }

    private void validateInput(String input, String errorMessage) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMessage);
        }
    }

    private void sendKafkaMessage(String topic, SystemLogs systemLog) {
        kafkaTemplate.send(topic, systemLog);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}