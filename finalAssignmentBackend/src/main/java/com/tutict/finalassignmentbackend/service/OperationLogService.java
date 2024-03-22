package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.OperationLogMapper;
import com.tutict.finalassignmentbackend.entity.OperationLog;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class OperationLogService {

    private final OperationLogMapper operationLogMapper;

    @Autowired
    public OperationLogService(OperationLogMapper operationLogMapper) {
        this.operationLogMapper = operationLogMapper;
    }

    public void CreateOperationLog(OperationLog operationLog) {
        operationLogMapper.insert(operationLog);
    }

    public OperationLog getOperationLog(int logId) {
        return operationLogMapper.selectById(logId);
    }

    public List<OperationLog> getAllOperationLogs() {
        return operationLogMapper.selectList(null);
    }

    public void updateOperationLog(OperationLog operationLog) {
        operationLogMapper.updateById(operationLog);
    }

    public void deleteOperationLog(int logId) {
        operationLogMapper.deleteById(logId);
    }

    // 根据时间范围查询操作日志
    public List<OperationLog> getOperationLogsByTimeRange(Date startTime, Date endTime) {
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("operation_time", startTime, endTime);
        return operationLogMapper.selectList(queryWrapper);
    }

    // 根据用户ID查询操作日志
    public List<OperationLog> getOperationLogsByUserId(String userId) {
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_id", userId);
        return operationLogMapper.selectList(queryWrapper);
    }

    // 根据操作结果查询操作日志
    public List<OperationLog> getOperationLogsByResult(String operationResult) {
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("operation_result", operationResult);
        return operationLogMapper.selectList(queryWrapper);
    }
}
