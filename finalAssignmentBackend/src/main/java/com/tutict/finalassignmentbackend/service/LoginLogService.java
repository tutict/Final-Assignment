package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.LoginLogMapper;
import com.tutict.finalassignmentbackend.entity.LoginLog;
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
public class LoginLogService {

    // 日志记录器，用于记录系统日志
    private static final Logger log = LoggerFactory.getLogger(LoginLogService.class);

    // 登录日志数据访问对象，用于数据库操作
    private final LoginLogMapper loginLogMapper;
    // Kafka模板，用于发送消息到Kafka
    private final KafkaTemplate<String, LoginLog> kafkaTemplate;

    // 构造函数，通过依赖注入初始化LoginLogMapper和KafkaTemplate
    @Autowired
    public LoginLogService(LoginLogMapper loginLogMapper, KafkaTemplate<String, LoginLog> kafkaTemplate) {
        this.loginLogMapper = loginLogMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    /**
     * 创建登录日志
     * @param loginLog 登录日志对象，包含要插入数据库的日志信息
     */
    @Transactional
    public void createLoginLog(LoginLog loginLog) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, LoginLog>> future = kafkaTemplate.send("login_create", loginLog);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Create message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            loginLogMapper.insert(loginLog);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    /**
     * 根据日志ID获取登录日志
     * @param logId 日志ID
     * @return 返回登录日志对象
     */
    public LoginLog getLoginLog(int logId) {
        return loginLogMapper.selectById(logId);
    }

    /**
     * 获取所有登录日志
     * @return 返回登录日志列表
     */
    public List<LoginLog> getAllLoginLogs() {
        return loginLogMapper.selectList(null);
    }

    /**
     * 更新登录日志
     * @param loginLog 登录日志对象，包含要更新的日志信息
     */
    @Transactional
    public void updateLoginLog(LoginLog loginLog) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, LoginLog>> future = kafkaTemplate.send("login_update", loginLog);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Update message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            loginLogMapper.updateById(loginLog);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    /**
     * 删除登录日志
     * @param logId 日志ID
     */
    public void deleteLoginLog(int logId) {
        try {
            loginLogMapper.deleteById(logId);
        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while deleting login log", e);
            // 抛出异常
            throw e;
        }
    }

    /**
     * 根据时间范围获取登录日志
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 返回在指定时间范围内的登录日志列表
     * @throws IllegalArgumentException 如果时间范围无效
     */
    public List<LoginLog> getLoginLogsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("login_time", startTime, endTime);
        return loginLogMapper.selectList(queryWrapper);
    }

    /**
     * 根据用户名获取登录日志
     * @param username 用户名
     * @return 返回指定用户名的登录日志列表
     * @throws IllegalArgumentException 如果用户名为空或无效
     */
    public List<LoginLog> getLoginLogsByUsername(String username) {
        if (username == null || username.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid username");
        }
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return loginLogMapper.selectList(queryWrapper);
    }

    /**
     * 根据登录结果获取登录日志
     * @param loginResult 登录结果
     * @return 返回指定登录结果的登录日志列表
     * @throws IllegalArgumentException 如果登录结果为空或无效
     */
    public List<LoginLog> getLoginLogsByLoginResult(String loginResult) {
        if (loginResult == null || loginResult.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid login result");
        }
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("login_result", loginResult);
        return loginLogMapper.selectList(queryWrapper);
    }
}
