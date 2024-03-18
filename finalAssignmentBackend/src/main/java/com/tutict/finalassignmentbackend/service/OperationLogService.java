package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.dao.OperationLogMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class OperationLogService {

    private final OperationLogMapper operationLogMapper;

    @Autowired
    public OperationLogService(OperationLogMapper operationLogMapper) {
        this.operationLogMapper = operationLogMapper;
    }
}
