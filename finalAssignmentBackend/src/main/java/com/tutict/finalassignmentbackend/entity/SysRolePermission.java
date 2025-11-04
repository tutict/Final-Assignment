package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 角色权限关联表实体类，对应数据库表 "sys_role_permission"
 * 用于定义角色和权限之间的多对多关系
 */
@Data
@TableName("sys_role_permission")
public class SysRolePermission implements Serializable {
    /**
     * 序列化版本 UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 关联 ID，主键，自动增长
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 角色 ID
     */
    @TableField("role_id")
    private Integer roleId;

    /**
     * 权限 ID
     */
    @TableField("permission_id")
    private Integer permissionId;

    /**
     * 创建时间
     */
    @TableField(value = "created_at", fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    /**
     * 创建人
     */
    @TableField("created_by")
    private String createdBy;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;
}