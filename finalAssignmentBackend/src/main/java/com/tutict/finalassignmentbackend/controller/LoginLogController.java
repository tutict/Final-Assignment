package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.LoginLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/loginlogs")
public class LoginLogController {

    private final LoginLogService loginLogService;

    @Autowired
    public LoginLogController(LoginLogService loginLogService) {
        this.loginLogService = loginLogService;
    }
}
