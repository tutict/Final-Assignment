package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
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

    private static final Logger log = LoggerFactory.getLogger(SystemLogsService.class);

    private final SystemLogsMapper systemLogsMapper;
    private final KafkaTemplate<String, SystemLogs> kafkaTemplate;

    @Autowired
    public SystemLogsService(SystemLogsMapper systemLogsMapper, KafkaTemplate<String, SystemLogs> kafkaTemplate) {
        this.systemLogsMapper = systemLogsMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 创建系统日志
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
        return systemLogsMapper.selectById(logId);
    }

    // 查询所有系统日志
    public List<SystemLogs> getAllSystemLogs() {
        return systemLogsMapper.selectList(null);
    }

    // 根据日志类型查询系统日志
    public List<SystemLogs> getSystemLogsByType(String logType) {
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("log_type", logType);
        return systemLogsMapper.selectList(queryWrapper);
    }

    // 根据操作时间范围查询系统日志
    public List<SystemLogs> getSystemLogsByTimeRange(Date startTime, Date endTime) {
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("operation_time", startTime, endTime);
        return systemLogsMapper.selectList(queryWrapper);
    }

    // 根据操作用户查询系统日志
    public List<SystemLogs> getSystemLogsByOperationUser(String operationUser) {
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("operation_user", operationUser);
        return systemLogsMapper.selectList(queryWrapper);
    }

    // 更新系统日志
    public void updateSystemLog(SystemLogs systemLog) {
        // 发送更新后的系统日志到 Kafka 主题
        kafkaTemplate.send("system_update", systemLog);
        systemLogsMapper.updateById(systemLog);
    }

    // 删除系统日志
    public void deleteSystemLog(int logId) {
        SystemLogs systemLogToDelete = systemLogsMapper.selectById(logId);
        if (systemLogToDelete != null) {
            systemLogsMapper.deleteById(logId);
        }
    }
}
