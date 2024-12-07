package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.OperationLog;
import finalassignmentbackend.mapper.OperationLogMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.mutiny.Uni;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.Date;
import java.util.List;
import java.util.concurrent.CompletionStage;
import java.util.logging.Logger;

@ApplicationScoped
public class OperationLogService {

    private static final Logger log = Logger.getLogger(OperationLogService.class.getName());

    @Inject
    OperationLogMapper operationLogMapper;

    @Inject
    @Channel("operation-events-out")
    MutinyEmitter<OperationLog> operationEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "operationCache")
    public void createOperationLog(OperationLog operationLog) {
        try {
            sendKafkaMessage("operation_create", operationLog);
            operationLogMapper.insert(operationLog);
        } catch (Exception e) {
            log.warning("Exception occurred while creating operation log or sending Kafka message");
            throw new RuntimeException("Failed to create operation log", e);
        }
    }

    @CacheResult(cacheName = "operationCache")
    public OperationLog getOperationLog(int logId) {
        return operationLogMapper.selectById(logId);
    }

    @CacheResult(cacheName = "operationCache")
    public List<OperationLog> getAllOperationLogs() {
        return operationLogMapper.selectList(null);
    }

    @Transactional
    @CacheInvalidate(cacheName = "operationCache")
    public void updateOperationLog(OperationLog operationLog) {
        try {
            sendKafkaMessage("operation_update", operationLog);
            operationLogMapper.updateById(operationLog);
        } catch (Exception e) {
            log.warning("Exception occurred while updating operation log or sending Kafka message");
            throw new RuntimeException("Failed to update operation log", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "operationCache")
    public void deleteOperationLog(int logId) {
        try {
            int result = operationLogMapper.deleteById(logId);
            if (result > 0) {
                log.info(String.format("Operation log with ID %s deleted successfully", logId));
            } else {
                log.severe(String.format("Failed to delete operation log with ID %s", logId));
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting operation log");
            throw new RuntimeException("Failed to delete operation log", e);
        }
    }

    @CacheResult(cacheName = "operationCache")
    public List<OperationLog> getOperationLogsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("operation_time", startTime, endTime);
        return operationLogMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "operationCache")
    public List<OperationLog> getOperationLogsByUserId(String userId) {
        if (userId == null || userId.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid userId");
        }
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_id", userId);
        return operationLogMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "operationCache")
    public List<OperationLog> getOperationLogsByResult(String operationResult) {
        if (operationResult == null || operationResult.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid operation result");
        }
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("operation_result", operationResult);
        return operationLogMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(String topic, OperationLog operationLog) {
        // 创建包含目标主题的元数据
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        // 创建包含负载和元数据的消息
        Message<OperationLog> message = Message.of(operationLog).addMetadata(metadata);

        // 使用 MutinyEmitter 的 sendMessage 方法返回 Uni<Void>
        Uni<Void> uni = operationEmitter.sendMessage(message);

        // 将 Uni<Void> 转换为 CompletionStage<Void>
        CompletionStage<Void> sendStage = uni.subscribe().asCompletionStage();

        sendStage.whenComplete((ignored, throwable) -> {
            if (throwable != null) {
                log.severe(String.format("Failed to send message to Kafka topic %s: %s", topic, throwable.getMessage()));
            } else {
                log.info(String.format("Message sent to Kafka topic %s successfully", topic));
            }
        });
    }
}
