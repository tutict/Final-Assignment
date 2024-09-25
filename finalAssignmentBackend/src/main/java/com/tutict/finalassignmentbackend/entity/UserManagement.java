package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 用户管理实体类
 * 该类表示用户管理系统的用户实体，包含用户的详细信息和相关操作
 * 实现Serializable接口，确保对象可以序列化，这对于数据库存储和网络传输是必要的
 */
@Data
@TableName("user_management")
public class UserManagement implements Serializable {
    // 序列化版本ID，用于保证序列化兼容性
    @Serial
    private static final long serialVersionUID = 1L;

    // 用户ID，主键，自动增长
    @TableId(value = "user_id", type = IdType.AUTO)
    private Integer userId;

    // 用户姓名
    @TableField("name")
    private String name;

    // 用户名，用于登录
    @TableField("username")
    private String username;

    // 密码，用于登录验证
    @TableField("password")
    private String password;

    // 联系电话
    @TableField("contact_number")
    private String contactNumber;

    // 电子邮件地址
    @TableField("email")
    private String email;

    // 用户类型，区分不同权限的用户
    @TableField("user_type")
    private String userType;

    // 用户状态，表示用户是否可用或是否被禁用
    @TableField("status")
    private String status;

    // 创建时间，记录用户信息创建的时间
    @TableField("created_time")
    private LocalDateTime createdTime;

    // 修改时间，记录用户信息最后一次修改的时间
    @TableField("modified_time")
    private LocalDateTime modifiedTime;

    // 备注，用于记录额外的用户信息
    @TableField("remarks")
    private String remarks;
}