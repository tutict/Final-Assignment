package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.dao.SystemSettingsMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SystemSettingsService {

    private final SystemSettingsMapper systemSettingsMapper;

    @Autowired
    public SystemSettingsService(SystemSettingsMapper systemSettingsMapper) {
        this.systemSettingsMapper = systemSettingsMapper;
    }
}
