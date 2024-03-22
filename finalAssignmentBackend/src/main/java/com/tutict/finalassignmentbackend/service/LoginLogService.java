package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.LoginLogMapper;
import com.tutict.finalassignmentbackend.entity.LoginLog;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class LoginLogService {

    private final LoginLogMapper loginLogMapper;

    @Autowired
    public LoginLogService(LoginLogMapper loginLogMapper) {
        this.loginLogMapper = loginLogMapper;
    }

    public void createLoginLog(LoginLog loginLog) {
        loginLogMapper.insert(loginLog);
    }

    public LoginLog getLoginLog(int logId) {
         return loginLogMapper.selectById(logId);
    }

    public List<LoginLog> getAllLoginLogs() {
       return loginLogMapper.selectList(null);
    }

    public void updateLoginLog(LoginLog loginLog) {
        loginLogMapper.updateById(loginLog);
    }

    public void deleteLoginLog(int logId) {
        loginLogMapper.deleteById(logId);
    }

    // getLoginLogsByTimeRange
    public List<LoginLog> getLoginLogsByTimeRange(Date startTime, Date endTime) {
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("login_time", startTime);
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
