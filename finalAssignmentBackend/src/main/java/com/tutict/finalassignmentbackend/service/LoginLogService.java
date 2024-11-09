package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.LoginLogMapper;
import com.tutict.finalassignmentbackend.entity.LoginLog;
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
    @CacheEvict(value = "loginCache", key = "#loginLog.logId")
    public void createLoginLog(LoginLog loginLog) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("login_create", loginLog);
            // 数据库插入
            loginLogMapper.insert(loginLog);
        } catch (Exception e) {
            log.error("Exception occurred while creating login log or sending Kafka message", e);
            throw new RuntimeException("Failed to create login log", e);
        }
    }

    /**
     * 根据日志ID获取登录日志
     * @param logId 日志ID
     * @return 返回登录日志对象
     */
    @Cacheable(value = "loginCache", key = "#logId")
    public LoginLog getLoginLog(int logId) {
        return loginLogMapper.selectById(logId);
    }

    /**
     * 获取所有登录日志
     * @return 返回登录日志列表
     */
    @Cacheable(value = "loginCache", key = "'allLoginLogs'")
    public List<LoginLog> getAllLoginLogs() {
        return loginLogMapper.selectList(null);
    }

    /**
     * 更新登录日志
     * @param loginLog 登录日志对象，包含要更新的日志信息
     */
    @Transactional
    @CachePut(value = "loginCache", key = "#loginLog.logId")
    public void updateLoginLog(LoginLog loginLog) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("login_update", loginLog);
            // 更新数据库记录
            loginLogMapper.updateById(loginLog);
        } catch (Exception e) {
            log.error("Exception occurred while updating login log or sending Kafka message", e);
            throw new RuntimeException("Failed to update login log", e);
        }
    }

    /**
     * 删除登录日志
     * @param logId 日志ID
     */
    @Transactional
    @CacheEvict(value = "loginCache", key = "#logId")
    public void deleteLoginLog(int logId) {
        try {
            int result = loginLogMapper.deleteById(logId);
            if (result > 0) {
                log.info("Login log with ID {} deleted successfully", logId);
            } else {
                log.error("Failed to delete login log with ID {}", logId);
            }
        } catch (Exception e) {
            log.error("Exception occurred while deleting login log", e);
            throw new RuntimeException("Failed to delete login log", e);
        }
    }

    /**
     * 根据时间范围获取登录日志
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 返回在指定时间范围内的登录日志列表
     * @throws IllegalArgumentException 如果时间范围无效
     */
    @Cacheable(value = "loginCache", key = "#root.methodName + '_' + #startTime + '-' + #endTime")
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
    @Cacheable(value = "loginCache", key = "#root.methodName + '_' + #username")
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
    @Cacheable(value = "loginCache", key = "#root.methodName + '_' + #loginResult")
    public List<LoginLog> getLoginLogsByLoginResult(String loginResult) {
        if (loginResult == null || loginResult.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid login result");
        }
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("login_result", loginResult);
        return loginLogMapper.selectList(queryWrapper);
    }

    // 发送 Kafka 消息的私有方法
    private void sendKafkaMessage(String topic, LoginLog loginLog) throws Exception {
        SendResult<String, LoginLog> sendResult = kafkaTemplate.send(topic, loginLog).get();
        log.info("Message sent to Kafka topic {} successfully: {}", topic, sendResult.toString());
    }
}
