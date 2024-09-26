package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.SystemLogsMapper;
import com.tutict.finalassignmentbackend.entity.SystemLogs;
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
public class SystemLogsService {

    // 日志记录器，用于记录应用的日志信息
    private static final Logger log = LoggerFactory.getLogger(SystemLogsService.class);

    // MyBatis映射器，用于执行系统日志的数据库操作
    private final SystemLogsMapper systemLogsMapper;
    // Kafka模板，用于发送消息到Kafka
    private final KafkaTemplate<String, SystemLogs> kafkaTemplate;

    // 构造函数，通过依赖注入初始化SystemLogsMapper和KafkaTemplate
    @Autowired
    public SystemLogsService(SystemLogsMapper systemLogsMapper, KafkaTemplate<String, SystemLogs> kafkaTemplate) {
        this.systemLogsMapper = systemLogsMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 创建系统日志
    // 使用事务确保操作的原子性：如果Kafka消息发送失败或数据库插入失败，会触发事务回滚
    @Transactional
    public void createSystemLog(SystemLogs systemLog) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, SystemLogs>> future =  kafkaTemplate.send("system_create", systemLog);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Create message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            systemLogsMapper.insert(systemLog);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    // 根据日志ID查询系统日志
    public SystemLogs getSystemLogById(int logId) {
        // 通过ID查询日志详情
        return systemLogsMapper.selectById(logId);
    }

    // 查询所有系统日志
    public List<SystemLogs> getAllSystemLogs() {
        // 查询并返回所有系统日志
        return systemLogsMapper.selectList(null);
    }

    /**
     * 根据日志类型查询系统日志
     * @param logType 日志类型
     * @return 查询到的日志列表
     * @throws IllegalArgumentException 如果日志类型为空或空字符串，则抛出此异常
     */
    public List<SystemLogs> getSystemLogsByType(String logType) {
        if (logType == null || logType.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid log type");
        }
        // 创建查询条件：根据日志类型查询
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("log_type", logType);
        // 执行查询并返回结果
        return systemLogsMapper.selectList(queryWrapper);
    }

    /**
     * 根据操作时间范围查询系统日志
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 查询到的日志列表
     * @throws IllegalArgumentException 如果时间范围无效（开始时间大于结束时间），则抛出此异常
     */
    public List<SystemLogs> getSystemLogsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        // 创建查询条件：根据操作时间范围查询
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("operation_time", startTime, endTime);
        // 执行查询并返回结果
        return systemLogsMapper.selectList(queryWrapper);
    }

    /**
     * 根据操作用户查询系统日志
     * @param operationUser 操作用户
     * @return 查询到的日志列表
     * @throws IllegalArgumentException 如果操作用户为空或空字符串，则抛出此异常
     */
    public List<SystemLogs> getSystemLogsByOperationUser(String operationUser) {
        if (operationUser == null || operationUser.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid operation user");
        }
        // 创建查询条件：根据操作用户查询
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("operation_user", operationUser);
        // 执行查询并返回结果
        return systemLogsMapper.selectList(queryWrapper);
    }

    // 更新系统日志
    // 使用事务确保操作的原子性：如果Kafka消息发送失败或数据库更新失败，会触发事务回滚
    @Transactional
    public void updateSystemLog(SystemLogs systemLog) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, SystemLogs>> future =   kafkaTemplate.send("system_update", systemLog);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Update message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            systemLogsMapper.updateById(systemLog);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    /**
     * 删除系统日志
     * @param logId 日志ID
     */
    public void deleteSystemLog(int logId) {
        try {
            // 根据ID查询待删除的日志，确保日志存在
            SystemLogs systemLogToDelete = systemLogsMapper.selectById(logId);
            if (systemLogToDelete != null) {
                // 删除日志
                systemLogsMapper.deleteById(logId);
            }
        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while deleting system log", e);
        }
    }
}
