package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.OperationLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/operationlogs")
public class OperationLogController {

    private final OperationLogService operationLogService;

    @Autowired
    public OperationLogController(OperationLogService operationLogService) {
        this.operationLogService = operationLogService;
    }
}
