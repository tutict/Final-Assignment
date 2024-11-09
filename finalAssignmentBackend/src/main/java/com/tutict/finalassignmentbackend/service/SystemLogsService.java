package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.SystemLogsMapper;
import com.tutict.finalassignmentbackend.entity.SystemLogs;
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
import java.util.concurrent.ExecutionException;

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

    /**
     * 创建系统日志
     * 使用事务确保操作的原子性：如果Kafka消息发送失败或数据库插入失败，会触发事务回滚
     * @param systemLog 系统日志对象
     */
    @Transactional
    @CacheEvict(cacheNames = "systemLogCache", key = "#systemLog.logId")
    public void createSystemLog(SystemLogs systemLog) {
        try {
            // 发送 Kafka 消息
            sendKafkaMessage("system_create", systemLog);
            // 插入系统日志到数据库
            systemLogsMapper.insert(systemLog);
        } catch (Exception e) {
            // 记录异常信息并抛出运行时异常
            log.error("Exception occurred while creating system log or sending Kafka message", e);
            throw new RuntimeException("Failed to create system log", e);
        }
    }

    /**
     * 根据日志ID查询系统日志
     * @param logId 日志ID
     * @return 查询到的系统日志对象
     */
    @Cacheable(cacheNames = "systemLogCache", key = "#logId")
    public SystemLogs getSystemLogById(int logId) {
        return systemLogsMapper.selectById(logId);
    }

    /**
     * 查询所有系统日志
     * @return 所有系统日志的列表
     */
    @Cacheable(cacheNames = "systemLogCache", key = "'allSystemLogs'")
    public List<SystemLogs> getAllSystemLogs() {
        return systemLogsMapper.selectList(null);
    }

    /**
     * 根据日志类型查询系统日志
     * @param logType 日志类型
     * @return 查询到的日志列表
     */
    @Cacheable(cacheNames = "systemLogCache", key = "#root.methodName + '_' + #logType")
    public List<SystemLogs> getSystemLogsByType(String logType) {
        if (logType == null || logType.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid log type");
        }
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("log_type", logType);
        return systemLogsMapper.selectList(queryWrapper);
    }

    /**
     * 根据操作时间范围查询系统日志
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 查询到的日志列表
     */
    @Cacheable(cacheNames = "systemLogCache", key = "#root.methodName + '_' + #startTime + '_' + #endTime")
    public List<SystemLogs> getSystemLogsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("operation_time", startTime, endTime);
        return systemLogsMapper.selectList(queryWrapper);
    }

    /**
     * 根据操作用户查询系统日志
     * @param operationUser 操作用户
     * @return 查询到的日志列表
     */
    @Cacheable(cacheNames = "systemLogCache", key = "#root.methodName + '_' + #operationUser")
    public List<SystemLogs> getSystemLogsByOperationUser(String operationUser) {
        if (operationUser == null || operationUser.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid operation user");
        }
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("operation_user", operationUser);
        return systemLogsMapper.selectList(queryWrapper);
    }

    /**
     * 更新系统日志
     * 使用事务确保操作的原子性：如果Kafka消息发送失败或数据库更新失败，会触发事务回滚
     * @param systemLog 系统日志对象
     */
    @Transactional
    @CachePut(cacheNames = "systemLogCache", key = "#systemLog.logId")
    public void updateSystemLog(SystemLogs systemLog) {
        try {
            // 发送 Kafka 消息
            sendKafkaMessage("system_update", systemLog);
            // 更新系统日志到数据库
            systemLogsMapper.updateById(systemLog);
        } catch (Exception e) {
            log.error("Exception occurred while updating system log or sending Kafka message", e);
            throw new RuntimeException("Failed to update system log", e);
        }
    }

    /**
     * 删除系统日志
     * @param logId 日志ID
     */
    @Transactional
    @CacheEvict(cacheNames = "systemLogCache", key = "#logId")
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

    // 发送 Kafka 消息的私有方法
    private void sendKafkaMessage(String topic, SystemLogs systemLog) throws ExecutionException, InterruptedException {
        SendResult<String, SystemLogs> sendResult = kafkaTemplate.send(topic, systemLog).get();
        log.info("Message sent to Kafka topic {} successfully: {}", topic, sendResult.toString());
    }
}