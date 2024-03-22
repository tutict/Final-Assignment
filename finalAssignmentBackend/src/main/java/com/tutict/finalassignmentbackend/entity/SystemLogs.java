package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("system_logs")
public class SystemLogs implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "log_id", type = IdType.AUTO)
    private Integer logId;

    @TableField("log_type")
    private String logType;

    @TableField("log_content")
    private String logContent;

    @TableField("operation_time")
    private LocalDateTime operationTime;

    @TableField("operation_user")
    private String operationUser;

    @TableField("operation_ip_address")
    private String operationIpAddress;

    @TableField("remarks")
    private String remarks;
}