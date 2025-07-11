package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 系统日志实体类
 * 该类用于映射数据库中的系统日志表，记录系统运行过程中的各种日志信息
 */
@Data
@TableName("system_logs")
public class SystemLogs implements Serializable {
    // 序列化版本标识
    @Serial
    private static final long serialVersionUID = 1L;

    // 日志ID，主键，自增
    @TableId(value = "log_id", type = IdType.AUTO)
    private Integer logId;

    // 日志类型
    @TableField("log_type")
    private String logType;

    // 日志内容
    @TableField("log_content")
    private String logContent;

    // 操作时间
    @TableField("operation_time")
    private LocalDateTime operationTime;

    // 操作用户
    @TableField("operation_user")
    private String operationUser;

    // 操作IP地址
    @TableField("operation_ip_address")
    private String operationIpAddress;

    // 备注信息
    @TableField("remarks")
    private String remarks;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;
}