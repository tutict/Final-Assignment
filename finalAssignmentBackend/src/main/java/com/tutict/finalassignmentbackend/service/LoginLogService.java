package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.LoginLogMapper;
import com.tutict.finalassignmentbackend.entity.LoginLog;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class LoginLogService {

    private final LoginLogMapper loginLogMapper;
    private final KafkaTemplate<String, LoginLog> kafkaTemplate;

    @Autowired
    public LoginLogService(LoginLogMapper loginLogMapper, KafkaTemplate<String, LoginLog> kafkaTemplate) {
        this.loginLogMapper = loginLogMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    public void createLoginLog(LoginLog loginLog) {
        // 发送登录日志到 Kafka 主题
        kafkaTemplate.send("login_create", loginLog);
        loginLogMapper.insert(loginLog);
    }

    public LoginLog getLoginLog(int logId) {
        return loginLogMapper.selectById(logId);
    }

    public List<LoginLog> getAllLoginLogs() {
        return loginLogMapper.selectList(null);
    }

    public void updateLoginLog(LoginLog loginLog) {
        kafkaTemplate.send("login_update", loginLog);
        loginLogMapper.updateById(loginLog);
    }

    public void deleteLoginLog(int logId) {
        loginLogMapper.deleteById(logId);
    }

    // getLoginLogsByTimeRange
    public List<LoginLog> getLoginLogsByTimeRange(Date startTime, Date endTime) {
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("login_time", startTime, endTime);
        return loginLogMapper.selectList(queryWrapper);
    }

    // getLoginLogsByUsername
    public List<LoginLog> getLoginLogsByUsername(String username) {
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return loginLogMapper.selectList(queryWrapper);
    }

    // getLoginLogsByLoginResult
    public List<LoginLog> getLoginLogsByLoginResult(String loginResult) {
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("login_result", loginResult);
        return loginLogMapper.selectList(queryWrapper);
    }
}
