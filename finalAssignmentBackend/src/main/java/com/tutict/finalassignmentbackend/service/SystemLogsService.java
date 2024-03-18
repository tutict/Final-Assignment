package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.dao.SystemLogsMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SystemLogsService {

    private final SystemLogsMapper systemLogsMapper;

    @Autowired
    public SystemLogsService(SystemLogsMapper systemLogsMapper) {
        this.systemLogsMapper = systemLogsMapper;
    }
}
