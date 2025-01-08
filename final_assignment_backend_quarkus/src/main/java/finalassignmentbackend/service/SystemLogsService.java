package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.RequestHistory;
import finalassignmentbackend.entity.SystemLogs;
import finalassignmentbackend.mapper.RequestHistoryMapper;
import finalassignmentbackend.mapper.SystemLogsMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Event;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.event.TransactionPhase;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import lombok.Getter;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.Date;
import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class SystemLogsService {

    private static final Logger log = Logger.getLogger(SystemLogsService.class.getName());

    @Inject
    SystemLogsMapper systemLogsMapper;

    @Inject
    RequestHistoryMapper requestHistoryMapper;

    @Inject
    Event<SystemLogEvent> systemLogEvent;

    @Inject
    @Channel("system-logs-out")
    MutinyEmitter<SystemLogs> systemLogsEmitter;

    @Getter
    public static class SystemLogEvent {
        private final SystemLogs systemLog;
        private final String action; // "create" or "update"

        public SystemLogEvent(SystemLogs systemLog, String action) {
            this.systemLog = systemLog;
            this.action = action;
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "systemLogCache")
    public void checkAndInsertIdempotency(String idempotencyKey, SystemLogs systemLogs, String action) {
        // 查询 request_history
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            // 已有此 key -> 重复请求
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
            // 若并发下同 key 导致唯一索引冲突
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        systemLogEvent.fire(new SystemLogsService.SystemLogEvent(systemLogs, action));

        Integer systemLogsId = systemLogs.getLogId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(systemLogsId);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheInvalidate(cacheName = "systemLogCache")
    public void createSystemLog(SystemLogs systemLog) {
        systemLogsMapper.insert(systemLog);
    }

    @Transactional
    @CacheInvalidate(cacheName = "systemLogCache")
    public void updateSystemLog(SystemLogs systemLog) {
        SystemLogs existingLog = systemLogsMapper.selectById(systemLog.getLogId());
        if (existingLog != null) {
            systemLogsMapper.updateById(systemLog);
        } else {
            log.warning(String.format("System log with ID %d not found. Cannot update.", systemLog.getLogId()));
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "systemLogCache")
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

    @CacheResult(cacheName = "systemLogCache")
    public SystemLogs getSystemLogById(int logId) {
        return systemLogsMapper.selectById(logId);
    }

    @CacheResult(cacheName = "systemLogCache")
    public List<SystemLogs> getAllSystemLogs() {
        return systemLogsMapper.selectList(null);
    }

    @CacheResult(cacheName = "systemLogCache")
    public List<SystemLogs> getSystemLogsByType(String logType) {
        if (logType == null || logType.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid log type");
        }
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("log_type", logType);
        return systemLogsMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "systemLogCache")
    public List<SystemLogs> getSystemLogsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("operation_time", startTime, endTime);
        return systemLogsMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "systemLogCache")
    public List<SystemLogs> getSystemLogsByOperationUser(String operationUser) {
        if (operationUser == null || operationUser.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid operation user");
        }
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("operation_user", operationUser);
        return systemLogsMapper.selectList(queryWrapper);
    }

    public void onSystemLogEvent(@Observes(during = TransactionPhase.AFTER_SUCCESS) SystemLogEvent event) {
        String topic = event.getAction().equals("create") ? "system_log_processed_create" : "system_log_processed_update";
        sendKafkaMessage(topic, event.getSystemLog());
    }

    private void sendKafkaMessage(String topic, SystemLogs systemLog) {
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        Message<SystemLogs> message = Message.of(systemLog).addMetadata(metadata);

        systemLogsEmitter.sendMessage(message)
                .await().indefinitely();

        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
