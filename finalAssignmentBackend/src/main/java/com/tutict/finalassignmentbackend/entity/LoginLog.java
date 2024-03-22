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
@TableName("login_log")
public class LoginLog implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "log_id", type = IdType.AUTO)
    private Integer logId;

    @TableField("username")
    private String username;

    @TableField("login_ip_address")
    private String loginIpAddress;

    @TableField("login_time")
    private LocalDateTime loginTime;

    @TableField("login_result")
    private String loginResult;

    @TableField("browser_type")
    private String browserType;

    @TableField("os_version")
    private String osVersion;

    @TableField("remarks")
    private String remarks;
}