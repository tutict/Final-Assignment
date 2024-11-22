package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.SystemLogsMapper;
import finalassignmentbackend.entity.SystemLogs;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.kafka.KafkaRecord;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import org.jboss.logging.Logger;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import java.util.Date;
import java.util.List;

@ApplicationScoped
public class SystemLogsService {

    private static final Logger log = Logger.getLogger(SystemLogsService.class);

    @Inject
    SystemLogsMapper systemLogsMapper;

    @Inject
    @Channel("system-logs-out")
    Emitter<SystemLogs> systemLogsEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "systemLogCache")
    public void createSystemLog(SystemLogs systemLog) {
        try {
            sendKafkaMessage("system_create", systemLog);
            systemLogsMapper.insert(systemLog);
        } catch (Exception e) {
            log.error("Exception occurred while creating system log or sending Kafka message", e);
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
            log.error("Exception occurred while updating system log or sending Kafka message", e);
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
            log.error("Exception occurred while deleting system log", e);
            throw new RuntimeException("Failed to delete system log", e);
        }
    }

    private void sendKafkaMessage(String topic, SystemLogs systemLog) {
        var metadata = OutgoingKafkaRecordMetadata.<String>builder().withTopic(topic).build();
        KafkaRecord<String, SystemLogs> record = (KafkaRecord<String, SystemLogs>) KafkaRecord.of(systemLog.getLogId().toString(), systemLog).addMetadata(metadata);
        systemLogsEmitter.send(record);
        log.info("Message sent to Kafka topic {} successfully");
    }
}
