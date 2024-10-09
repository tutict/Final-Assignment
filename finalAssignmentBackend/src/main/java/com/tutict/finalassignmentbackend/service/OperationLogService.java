package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.OperationLogMapper;
import com.tutict.finalassignmentbackend.entity.OperationLog;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@Service
public class OperationLogService {

    // Logger实例，用于记录应用日志
    private static final Logger log = LoggerFactory.getLogger(OperationLogService.class);

    // 操作日志数据访问对象，用于执行数据库操作
    private final OperationLogMapper operationLogMapper;
    // Kafka模板，用于发送消息到Kafka
    private final KafkaTemplate<String, OperationLog> kafkaTemplate;

    // 构造函数，通过依赖注入初始化OperationLogMapper和KafkaTemplate
    @Autowired
    public OperationLogService(OperationLogMapper operationLogMapper, KafkaTemplate<String, OperationLog> kafkaTemplate) {
        this.operationLogMapper = operationLogMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    /**
     * 创建操作日志
     * @param operationLog 待创建的操作日志对象
     */
    @Transactional
    @CacheEvict(value = "operationCache", allEntries = true, key = "#operationLog.logId")
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

    /**
     * 根据日志ID获取操作日志
     * @param logId 操作日志的ID
     * @return 对应ID的操作日志对象
     */
    @Cacheable(value = "operationCache", key = "#logId")
    public OperationLog getOperationLog(int logId) {
        return operationLogMapper.selectById(logId);
    }

    /**
     * 获取所有操作日志
     * @return 包含所有操作日志的列表
     */
    @Cacheable(value = "operationCache")
    public List<OperationLog> getAllOperationLogs() {
        return operationLogMapper.selectList(null);
    }

    /**
     * 更新操作日志
     * @param operationLog 待更新的操作日志对象
     */
    @Transactional
    @CachePut(value = "operationCache", key = "#operationLog.logId")
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

    /**
     * 根据日志ID删除操作日志
     * @param logId 操作日志的ID
     */
    @CacheEvict(value = "operationCache", key = "#logId")
    public void deleteOperationLog(int logId) {
        try {
            operationLogMapper.deleteById(logId);
        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while deleting operation log", e);
        }
    }

    /**
     * 根据时间范围查询操作日志
     * @param startTime 查询的开始时间
     * @param endTime 查询的结束时间
     * @return 在指定时间范围内的操作日志列表
     * @throws IllegalArgumentException 如果时间范围无效
     */
    @Cacheable(value = "operationCache", key = "#startTime + '-' + #endTime")
    public List<OperationLog> getOperationLogsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("operation_time", startTime, endTime);
        return operationLogMapper.selectList(queryWrapper);
    }

    /**
     * 根据用户ID查询操作日志
     * @param userId 用户ID
     * @return 对应用户ID的操作日志列表
     * @throws IllegalArgumentException 如果用户ID无效
     */
    @Cacheable(value = "operationCache", key = "#userId")
    public List<OperationLog> getOperationLogsByUserId(String userId) {
        if (userId == null || userId.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid userId");
        }
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_id", userId);
        return operationLogMapper.selectList(queryWrapper);
    }

    /**
     * 根据操作结果查询操作日志
     * @param operationResult 操作结果
     * @return 对应操作结果的操作日志列表
     * @throws IllegalArgumentException 如果操作结果无效
     */
    @Cacheable(value = "operationCache", key = "#operationResult")
    public List<OperationLog> getOperationLogsByResult(String operationResult) {
        if (operationResult == null || operationResult.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid operation result");
        }
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("operation_result", operationResult);
        return operationLogMapper.selectList(queryWrapper);
    }
}
