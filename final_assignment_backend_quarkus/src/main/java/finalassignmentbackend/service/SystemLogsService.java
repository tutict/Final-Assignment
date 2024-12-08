package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.SystemLogs;
import finalassignmentbackend.mapper.SystemLogsMapper;
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
public class SystemLogsService {

    private static final Logger log = Logger.getLogger(SystemLogsService.class.getName());

    @Inject
    SystemLogsMapper systemLogsMapper;

    @Inject
    @Channel("system-logs-out")
    MutinyEmitter<SystemLogs> systemLogsEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "systemLogCache")
    public void createSystemLog(SystemLogs systemLog) {
        try {
            sendKafkaMessage("system_create", systemLog);
            systemLogsMapper.insert(systemLog);
        } catch (Exception e) {
            log.warning("Exception occurred while creating system log or sending Kafka message");
            throw new RuntimeException("Failed to create system log", e);
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

    @Transactional
    @CacheInvalidate(cacheName = "systemLogCache")
    public void updateSystemLog(SystemLogs systemLog) {
        try {
            sendKafkaMessage("system_update", systemLog);
            systemLogsMapper.updateById(systemLog);
        } catch (Exception e) {
            log.warning("Exception occurred while updating system log or sending Kafka message");
            throw new RuntimeException("Failed to update system log", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "systemLogCache")
    public void deleteSystemLog(int logId) {
        try {
            SystemLogs systemLogToDelete = systemLogsMapper.selectById(logId);
            if (systemLogToDelete != null) {
                systemLogsMapper.deleteById(logId);
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting system log");
            throw new RuntimeException("Failed to delete system log", e);
        }
    }

    private void sendKafkaMessage(String topic, SystemLogs systemLog) {
        // 创建包含目标主题的元数据
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        // 创建包含负载和元数据的消息
        Message<SystemLogs> message = Message.of(systemLog).addMetadata(metadata);

        // 使用 MutinyEmitter 的 sendMessage 方法返回 Uni<Void>
        Uni<Void> uni = systemLogsEmitter.sendMessage(message);

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
