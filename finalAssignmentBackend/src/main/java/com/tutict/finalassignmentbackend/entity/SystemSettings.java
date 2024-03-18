package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("system_settings")
public class SystemSettings {

    private String systemName;
    private String systemVersion;
    private String systemDescription;
    private String copyrightInfo;
    private String storagePath;
    private int loginTimeout;
    private int sessionTimeout;
    private String dateFormat;
    private int pageSize;
    private String smtpServer;
    private String emailAccount;
    private String emailPassword;
    private String remarks;
}
