package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 系统角色表实体类，对应数据库表 "sys_role"
 * 用于定义系统中的角色信息
 */
@Data
@TableName("sys_role")
public class SysRole implements Serializable {
    /**
     * 序列化版本 UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 角色 ID，主键，自动增长
     */
    @TableId(value = "role_id", type = IdType.AUTO)
    private Integer roleId;

    /**
     * 角色编码
     */
    @TableField("role_code")
    private String roleCode;

    /**
     * 角色名称
     */
    @TableField("role_name")
    private String roleName;

    /**
     * 角色类型 (System, Business, Custom)
     */
    @TableField("role_type")
    private String roleType;

    /**
     * 角色描述
     */
    @TableField("role_description")
    private String roleDescription;

    /**
     * 数据权限范围 (All, Department, Department_And_Sub, Self, Custom)
     */
    @TableField("data_scope")
    private String dataScope;

    /**
     * 状态 (Active, Inactive)
     */
    @TableField("status")
    private String status;

    /**
     * 排序
     */
    @TableField("sort_order")
    private Integer sortOrder;

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
     * 创建人
     */
    @TableField("created_by")
    private String createdBy;

    /**
     * 更新人
     */
    @TableField("updated_by")
    private String updatedBy;

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