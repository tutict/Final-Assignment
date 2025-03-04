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
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "user_id", type = IdType.AUTO)
    private Integer userId;

    @TableField("username")
    private String username;

    @TableField("password")
    private String password;

    @TableField("contact_number")
    private String contactNumber;

    @TableField("email")
    private String email;

    @TableField("status")
    private String status;

    @TableField("created_time")
    private LocalDateTime createdTime;

    @TableField("modified_time")
    private LocalDateTime modifiedTime;

    @TableField("remarks")
    private String remarks;
}