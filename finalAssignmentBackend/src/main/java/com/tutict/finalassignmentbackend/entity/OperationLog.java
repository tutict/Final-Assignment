package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 操作日志实体类
 * 该类用于映射数据库中的操作日志表，记录系统中的各种操作信息
 */
@Data
@TableName("operation_log")
public class OperationLog implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 日志ID，主键
     * 使用自动增长方式生成ID
     */
    @TableId(value = "log_id", type = IdType.AUTO)
    private Integer logId;

    /**
     * 用户ID，记录执行操作的用户
     */
    @TableField("user_id")
    private Integer userId;

    /**
     * 操作时间，记录操作发生的时间
     */
    @TableField("operation_time")
    private LocalDateTime operationTime;

    /**
     * 操作IP地址，记录操作发起的IP地址
     */
    @TableField("operation_ip_address")
    private String operationIpAddress;

    /**
     * 操作内容，描述具体的操作行为
     */
    @TableField("operation_content")
    private String operationContent;

    /**
     * 操作结果，记录操作的执行结果
     */
    @TableField("operation_result")
    private String operationResult;

    /**
     * 备注，用于记录额外的说明信息
     */
    @TableField("remarks")
    private String remarks;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;
}