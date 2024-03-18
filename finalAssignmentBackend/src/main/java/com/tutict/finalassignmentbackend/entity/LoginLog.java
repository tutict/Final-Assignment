package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.util.Date;

@Data
@TableName("login_log")
public class LoginLog {

    private int logId;
    private String username;
    private String loginIpAddress;
    private Date loginTime;
    private String loginResult;
    private String browserType;
    private String osVersion;
    private String remarks;
}
