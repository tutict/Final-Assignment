package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.OperationLog;
import finalassignmentbackend.entity.RequestHistory;
import finalassignmentbackend.mapper.OperationLogMapper;
import finalassignmentbackend.mapper.RequestHistoryMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.quarkus.runtime.annotations.RegisterForReflection;
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
@RegisterForReflection
public class OperationLogService {

    private static final Logger log = Logger.getLogger(OperationLogService.class.getName());

    @Inject
    OperationLogMapper operationLogMapper;

    @Inject
    RequestHistoryMapper requestHistoryMapper;

    @Inject
    Event<OperationLogEvent> operationLogEvent;

    @Inject
    @Channel("operation-events-out")
    MutinyEmitter<OperationLog> operationEmitter;

    @Getter
    public static class OperationLogEvent {
        private final OperationLog operationLog;
        private final String action; // "create" or "update"

        public OperationLogEvent(OperationLog operationLog, String action) {
            this.operationLog = operationLog;
            this.action = action;
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "operationCache")
    @WsAction(service = "OperationLogService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, OperationLog operationLog, String action) {
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

        operationLogEvent.fire(new OperationLogService.OperationLogEvent(operationLog, action));

        Integer operationId = operationLog.getLogId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(operationId);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheInvalidate(cacheName = "operationCache")
    public void createOperationLog(OperationLog operationLog) {
        OperationLog existingLog = operationLogMapper.selectById(operationLog.getLogId());
        if (existingLog == null) {
            operationLogMapper.insert(operationLog);
        } else {
            operationLogMapper.updateById(operationLog);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "operationCache")
    public void updateOperationLog(OperationLog operationLog) {
        OperationLog existingLog = operationLogMapper.selectById(operationLog.getLogId());
        if (existingLog == null) {
            operationLogMapper.insert(operationLog);
        } else {
            operationLogMapper.updateById(operationLog);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "operationCache")
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

    @CacheResult(cacheName = "operationCache")
    @WsAction(service = "OperationLogService", action = "getOperationLog")
    public OperationLog getOperationLog(Integer logId) {
        if (logId == null || logId <= 0 || logId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid log ID" + logId);
        }
        return operationLogMapper.selectById(logId);
    }

    @CacheResult(cacheName = "operationCache")
    @WsAction(service = "OperationLogService", action = "getAllOperationLogs")
    public List<OperationLog> getAllOperationLogs() {
        return operationLogMapper.selectList(null);
    }

    @CacheResult(cacheName = "operationCache")
    @WsAction(service = "OperationLogService", action = "getOperationLogsByTimeRange")
    public List<OperationLog> getOperationLogsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("operation_time", startTime, endTime);
        return operationLogMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "operationCache")
    @WsAction(service = "OperationLogService", action = "getOperationLogsByUserId")
    public List<OperationLog> getOperationLogsByUserId(String userId) {
        if (userId == null || userId.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid userId");
        }
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_id", userId);
        return operationLogMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "operationCache")
    @WsAction(service = "OperationLogService", action = "getOperationLogsByResult")
    public List<OperationLog> getOperationLogsByResult(String operationResult) {
        if (operationResult == null || operationResult.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid operation result");
        }
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("operation_result", operationResult);
        return operationLogMapper.selectList(queryWrapper);
    }

    public void onOperationLogEvent(@Observes(during = TransactionPhase.AFTER_SUCCESS) OperationLogEvent event) {
        String topic = event.getAction().equals("create") ? "operation_processed_create" : "operation_processed_update";
        sendKafkaMessage(topic, event.getOperationLog());
    }

    private void sendKafkaMessage(String topic, OperationLog operationLog) {
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        Message<OperationLog> message = Message.of(operationLog).addMetadata(metadata);

        operationEmitter.sendMessage(message)
                .await().indefinitely();

        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
