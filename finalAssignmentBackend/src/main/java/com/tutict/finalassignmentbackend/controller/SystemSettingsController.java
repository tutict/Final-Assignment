package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.SystemSettingsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/settings")
public class SystemSettingsController {

    private final SystemSettingsService systemSettingsService;

    @Autowired
    public SystemSettingsController(SystemSettingsService systemSettingsService) {
        this.systemSettingsService = systemSettingsService;
    }
}
