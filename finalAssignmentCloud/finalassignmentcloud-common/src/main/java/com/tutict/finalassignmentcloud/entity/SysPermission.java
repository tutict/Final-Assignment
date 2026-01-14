package com.tutict.finalassignmentcloud.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 系统权限表实体类，对应数据库表"sys_permission"
 * 用于定义系统中的权限信息
 */
@Data
@TableName("sys_permission")
public class SysPermission implements Serializable {
    /**
     * 序列化版本UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 权限 ID，主键，自动增长
     */
    @TableId(value = "permission_id", type = IdType.AUTO)
    private Integer permissionId;

    /**
     * 父权限ID (0表示顶级)
     */
    @TableField("parent_id")
    private Integer parentId;

    /**
     * 权限编码
     */
    @TableField("permission_code")
    private String permissionCode;

    /**
     * 权限名称
     */
    @TableField("permission_name")
    private String permissionName;

    /**
     * 权限类型 (Menu, Button, API, Data)
     */
    @TableField("permission_type")
    private String permissionType;

    /**
     * 权限描述
     */
    @TableField("permission_description")
    private String permissionDescription;

    /**
     * 菜单路径
     */
    @TableField("menu_path")
    private String menuPath;

    /**
     * 菜单图标
     */
    @TableField("menu_icon")
    private String menuIcon;

    /**
     * 组件路径
     */
    @TableField("component")
    private String component;

    /**
     * API路径
     */
    @TableField("api_path")
    private String apiPath;

    /**
     * API方法 (GET, POST, PUT, DELETE)
     */
    @TableField("api_method")
    private String apiMethod;

    /**
     * 是否可见 (1=是 0=否)
     */
    @TableField("is_visible")
    private Boolean isVisible;

    /**
     * 是否外部链接 (1=是 0=否)
     */
    @TableField("is_external")
    private Boolean isExternal;

    /**
     * 排序
     */
    @TableField("sort_order")
    private Integer sortOrder;

    /**
     * 状态 (Active, Inactive)
     */
    @TableField("status")
    private String status;

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

