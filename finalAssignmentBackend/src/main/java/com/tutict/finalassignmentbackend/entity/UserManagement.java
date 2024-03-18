package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("user_management")
public class UserManagement {

    private int userId;
    private String name;
    private String username;
    private String password;
    private String contactNumber;
    private String email;
    private String userType;
    private String status;
    private Date createdTime;
    private Date modifiedTime;
    private String remarks;
}
