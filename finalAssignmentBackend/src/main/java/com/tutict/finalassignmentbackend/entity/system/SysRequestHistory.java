package com.tutict.finalassignmentbackend.entity.system;

import com.baomidou.mybatisplus.annotation.*;
import com.fasterxml.jackson.annotation.JsonAlias;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 请求历史表实体类，对应数据库表 "sys_request_history"
 * 用于幂等性控制，防止重复提交
 */
@Data
@TableName("sys_request_history")
public class SysRequestHistory implements Serializable {
    /**
     * 序列化版本 UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 记录 ID，主键，自动增长
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 幂等性键
     */
    @TableField("idempotency_key")
    private String idempotencyKey;

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
    @JsonAlias("details")
    @TableField("request_params")
    private String requestParams;

    /**
     * 业务类型
     */
    @JsonAlias("title")
    @TableField("business_type")
    private String businessType;

    /**
     * 业务 ID
     */
    @TableField("business_id")
    private Long businessId;

    /**
     * 业务状态
     */
    @JsonAlias("status")
    @TableField("business_status")
    private String businessStatus;

    /**
     * 用户 ID
     */
    @TableField("user_id")
    private Long userId;

    /**
     * 前端进度消息用用户名提交。不入库，写入前解析成 userId。
     */
    @TableField(exist = false)
    private String username;

    /**
     * 请求 IP
     */
    @TableField("request_ip")
    private String requestIp;

    /**
     * 创建时间
     */
    @TableField(value = "created_at", fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    /**
     * 更新时间
     */
    @TableField(value = "updated_at", fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;
}