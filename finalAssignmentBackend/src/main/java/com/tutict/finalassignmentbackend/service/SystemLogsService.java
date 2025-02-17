package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.SystemLogsMapper;
import com.tutict.finalassignmentbackend.entity.SystemLogs;
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
public class SystemLogsService {

    private static final Logger log = Logger.getLogger(SystemLogsService.class.getName());

    private final SystemLogsMapper systemLogsMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, SystemLogs> kafkaTemplate;

    @Autowired
    public SystemLogsService(SystemLogsMapper systemLogsMapper,
                             RequestHistoryMapper requestHistoryMapper,
                             KafkaTemplate<String, SystemLogs> kafkaTemplate) {
        this.systemLogsMapper = systemLogsMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "systemLogCache", allEntries = true)
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

        sendKafkaMessage(systemLogs);

        Integer systemLogsId = systemLogs.getLogId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(systemLogsId);
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
    public SystemLogs getSystemLogById(Integer logId) {
        if (logId == null || logId <= 0 || logId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid log ID" + logId);
        }
        return systemLogsMapper.selectById(logId);
    }

    @Cacheable(cacheNames = "systemLogCache")
    public List<SystemLogs> getAllSystemLogs() {
        return systemLogsMapper.selectList(null);
    }

    @Cacheable(cacheNames = "systemLogCache")
    public List<SystemLogs> getSystemLogsByType(String logType) {
        if (logType == null || logType.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid log type");
        }
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("log_type", logType);
        return systemLogsMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "systemLogCache")
    public List<SystemLogs> getSystemLogsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("operation_time", startTime, endTime);
        return systemLogsMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "systemLogCache")
    public List<SystemLogs> getSystemLogsByOperationUser(String operationUser) {
        if (operationUser == null || operationUser.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid operation user");
        }
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("operation_user", operationUser);
        return systemLogsMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(SystemLogs systemLog) {
        kafkaTemplate.send("system_log_processed_topic", systemLog);
        log.info(String.format("Message sent to Kafka topic %s successfully", "system_log_processed_topic"));
    }
}