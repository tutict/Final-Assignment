package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.OperationLogMapper;
import com.tutict.finalassignmentbackend.entity.OperationLog;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@Service
public class OperationLogService {

    private static final Logger log = LoggerFactory.getLogger(OperationLogService.class);


    private final OperationLogMapper operationLogMapper;
    private final KafkaTemplate<String, OperationLog> kafkaTemplate;

    @Autowired
    public OperationLogService(OperationLogMapper operationLogMapper, KafkaTemplate<String, OperationLog> kafkaTemplate) {
        this.operationLogMapper = operationLogMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    public void createOperationLog(OperationLog operationLog) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, OperationLog>> future = kafkaTemplate.send("operation_create", operationLog);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Create message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            operationLogMapper.insert(operationLog);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    public OperationLog getOperationLog(int logId) {
        return operationLogMapper.selectById(logId);
    }

    public List<OperationLog> getAllOperationLogs() {
        return operationLogMapper.selectList(null);
    }

    @Transactional
    public void updateOperationLog(OperationLog operationLog) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, OperationLog>> future = kafkaTemplate.send("operation_update", operationLog);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Update message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            operationLogMapper.updateById(operationLog);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    public void deleteOperationLog(int logId) {
        operationLogMapper.deleteById(logId);
    }

    // 根据时间范围查询操作日志
    public List<OperationLog> getOperationLogsByTimeRange(Date startTime, Date endTime) {
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("operation_time", startTime, endTime);
        return operationLogMapper.selectList(queryWrapper);
    }

    // 根据用户ID查询操作日志
    public List<OperationLog> getOperationLogsByUserId(String userId) {
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_id", userId);
        return operationLogMapper.selectList(queryWrapper);
    }

    // 根据操作结果查询操作日志
    public List<OperationLog> getOperationLogsByResult(String operationResult) {
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("operation_result", operationResult);
        return operationLogMapper.selectList(queryWrapper);
    }
}
