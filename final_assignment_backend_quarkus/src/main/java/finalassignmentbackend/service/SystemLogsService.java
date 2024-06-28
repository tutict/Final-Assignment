package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.SystemLogsMapper;
import finalassignmentbackend.entity.SystemLogs;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Date;
import java.util.List;

@ApplicationScoped
public class SystemLogsService {

    private static final Logger log = LoggerFactory.getLogger(SystemLogsService.class);

    @Inject
    SystemLogsMapper systemLogsMapper;

    @Inject
    @Channel("system_create")
    Emitter<SystemLogs> systemCreateEmitter;

    @Inject
    @Channel("system_update")
    Emitter<SystemLogs> systemUpdateEmitter;

    // 创建系统日志
    @Transactional
    public void createSystemLog(SystemLogs systemLog) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            systemCreateEmitter.send(systemLog).toCompletableFuture().exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            systemLogsMapper.insert(systemLog);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
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
    @Transactional
    public void updateSystemLog(SystemLogs systemLog) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            systemUpdateEmitter.send(systemLog).toCompletableFuture().exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            systemLogsMapper.updateById(systemLog);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    // 删除系统日志
    public void deleteSystemLog(int logId) {
        SystemLogs systemLogToDelete = systemLogsMapper.selectById(logId);
        if (systemLogToDelete != null) {
            systemLogsMapper.deleteById(logId);
        }
    }
}
