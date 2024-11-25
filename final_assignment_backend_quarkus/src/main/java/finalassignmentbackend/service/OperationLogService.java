package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.OperationLog;
import finalassignmentbackend.mapper.OperationLogMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.kafka.KafkaRecord;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;

import java.util.Date;
import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class OperationLogService {

    private static final Logger log = Logger.getLogger(String.valueOf(OperationLogService.class));

    @Inject
    OperationLogMapper operationLogMapper;

    @Inject
    @Channel("operation-events-out")
    Emitter<OperationLog> operationEmitter;

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
        var metadata = OutgoingKafkaRecordMetadata.<String>builder().withTopic(topic).build();
        KafkaRecord<String, OperationLog> record = (KafkaRecord<String, OperationLog>) KafkaRecord.of(operationLog.getLogId().toString(), operationLog).addMetadata(metadata);
        operationEmitter.send(record);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
