package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.dao.LoginLogMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class LoginLogService {

    private final LoginLogMapper loginLogMapper;

    @Autowired
    public LoginLogService(LoginLogMapper loginLogMapper) {
        this.loginLogMapper = loginLogMapper;
    }
}
