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
@TableName("user_management")
public class UserManagement implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "user_id", type = IdType.AUTO)
    private Integer userId;

    @TableField("name")
    private String name;

    @TableField("username")
    private String username;

    @TableField("password")
    private String password;

    @TableField("contact_number")
    private String contactNumber;

    @TableField("email")
    private String email;

    @TableField("user_type")
    private String userType;

    @TableField("status")
    private String status;

    @TableField("created_time")
    private LocalDateTime createdTime;

    @TableField("modified_time")
    private LocalDateTime modifiedTime;

    @TableField("remarks")
    private String remarks;
}