package com.tutict.finalassignmentcloud.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 操作日志表实体类，对应数据库表"audit_operation_log"
 * 用于记录系统用户的操作行为及结果
 */
@Data
@TableName("audit_operation_log")
public class AuditOperationLog implements Serializable {
    /**
     * 序列化版本UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 日志 ID，主键，自动增长
     */
    @TableId(value = "log_id", type = IdType.AUTO)
    private Long logId;

    /**
     * 操作类型 (INSERT, UPDATE, DELETE, SELECT, EXPORT)
     */
    @TableField("operation_type")
    private String operationType;

    /**
     * 操作模块
     */
    @TableField("operation_module")
    private String operationModule;

    /**
     * 操作功能
     */
    @TableField("operation_function")
    private String operationFunction;

    /**
     * 操作内容
     */
    @TableField("operation_content")
    private String operationContent;

    /**
     * 操作时间
     */
    @TableField("operation_time")
    private LocalDateTime operationTime;

    /**
     * 用户 ID
     */
    @TableField("user_id")
    private Long userId;

    /**
     * 用户名
     */
    @TableField("username")
    private String username;

    /**
     * 真实姓名
     */
    @TableField("real_name")
    private String realName;

    /**
     * 请求方法
     */
    @TableField("request_method")
    private String requestMethod;

    /**
     * 请求 URL
     */
    @TableField("request_url")
    private String requestUrl;

    /**
     * 请求参数
     */
    @TableField("request_params")
    private String requestParams;

    /**
     * 请求 IP
     */
    @TableField("request_ip")
    private String requestIp;

    /**
     * 操作结果 (Success, Failed, Exception)
     */
    @TableField("operation_result")
    private String operationResult;

    /**
     * 响应数据
     */
    @TableField("response_data")
    private String responseData;

    /**
     * 错误信息
     */
    @TableField("error_message")
    private String errorMessage;

    /**
     * 执行时长 (毫秒)
     */
    @TableField("execution_time")
    private Integer executionTime;

    /**
     * 变更前数据 (JSON)
     */
    @TableField("old_value")
    private String oldValue;

    /**
     * 变更后数据 (JSON)
     */
    @TableField("new_value")
    private String newValue;

    /**
     * 创建时间
     */
    @TableField(value = "created_at", fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;

    /**
     * 备注
     */
    @TableField("remarks")
    private String remarks;
}

