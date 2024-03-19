package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.SystemLogsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/systemlogs")
public class SystemLogsController {

    private final SystemLogsService systemLogsService;

    @Autowired
    public SystemLogsController(SystemLogsService systemLogsService) {
        this.systemLogsService = systemLogsService;
    }
}
