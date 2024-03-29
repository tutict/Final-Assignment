package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.SystemLogsMapper;
import com.tutict.finalassignmentbackend.entity.SystemLogs;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class SystemLogsService {

    private final SystemLogsMapper systemLogsMapper;

    @Autowired
    public SystemLogsService(SystemLogsMapper systemLogsMapper) {
        this.systemLogsMapper = systemLogsMapper;
    }

    // 创建系统日志
    public void createSystemLog(SystemLogs systemLog) {
        systemLogsMapper.insert(systemLog);
    }

    // 根据日志ID查询系统日志
    public SystemLogs getSystemLogById(int logId) {
        return systemLogsMapper.selectById(logId);
    }

    // 查询所有系统日志
    public List<SystemLogs> getAllSystemLogs() {
        return systemLogsMapper.selectList(null);
    }

    // 根据日志类型查询系统日志
    public List<SystemLogs> getSystemLogsByType(String logType) {
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("log_type", logType);
        return systemLogsMapper.selectList(queryWrapper);
    }

    // 根据操作时间范围查询系统日志
    public List<SystemLogs> getSystemLogsByTimeRange(Date startTime, Date endTime) {
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("operation_time", startTime, endTime);
        return systemLogsMapper.selectList(queryWrapper);
    }

    // 根据操作用户查询系统日志
    public List<SystemLogs> getSystemLogsByOperationUser(String operationUser) {
        QueryWrapper<SystemLogs> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("operation_user", operationUser);
        return systemLogsMapper.selectList(queryWrapper);
    }

    // 更新系统日志
    public void updateSystemLog(SystemLogs systemLog) {
        systemLogsMapper.updateById(systemLog);
    }

    // 删除系统日志
    public void deleteSystemLog(int logId) {
        systemLogsMapper.deleteById(logId);
    }

}