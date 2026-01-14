package com.tutict.finalassignmentcloud.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 系统用户表实体类，对应数据库表"sys_user"
 * 用于管理系统用户的基本信息和安全信息
 */
@Data
@TableName("sys_user")
public class SysUser implements Serializable {
    /**
     * 序列化版本UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 用户 ID，主键，自动增长
     */
    @TableId(value = "user_id", type = IdType.AUTO)
    private Long userId;

    /**
     * 用户名
     */
    @TableField("username")
    private String username;

    /**
     * 密码 (加密存储)
     */
    @TableField("password")
    private String password;

    /**
     * 密码盐值
     */
    @TableField("salt")
    private String salt;

    /**
     * 真实姓名
     */
    @TableField("real_name")
    private String realName;

    /**
     * 身份证号
     */
    @TableField("id_card_number")
    private String idCardNumber;

    /**
     * 性别 (Male, Female, Other)
     */
    @TableField("gender")
    private String gender;

    /**
     * 联系电话
     */
    @TableField("contact_number")
    private String contactNumber;

    /**
     * 电子邮箱
     */
    @TableField("email")
    private String email;

    /**
     * 所属部门
     */
    @TableField("department")
    private String department;

    /**
     * 职位
     */
    @TableField("position")
    private String position;

    /**
     * 工号
     */
    @TableField("employee_number")
    private String employeeNumber;

    /**
     * 账号状态(Active, Inactive, Locked, Expired)
     */
    @TableField("status")
    private String status;

    /**
     * 账号有效性
     */
    @TableField("account_expiry_date")
    private LocalDate accountExpiryDate;

    /**
     * 登录失败次数
     */
    @TableField("login_failures")
    private Integer loginFailures;

    /**
     * 最后登录时间
     */
    @TableField("last_login_time")
    private LocalDateTime lastLoginTime;

    /**
     * 最后登录IP
     */
    @TableField("last_login_ip")
    private String lastLoginIp;

    /**
     * 密码修改时间
     */
    @TableField("password_update_time")
    private LocalDateTime passwordUpdateTime;

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

