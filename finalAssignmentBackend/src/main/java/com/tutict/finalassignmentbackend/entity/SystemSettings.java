package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;

@Data
@TableName("system_settings")
public class SystemSettings implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "system_name")
    private String systemName;

    @TableField("system_version")
    private String systemVersion;

    @TableField("system_description")
    private String systemDescription;

    @TableField("copyright_info")
    private String copyrightInfo;

    @TableField("storage_path")
    private String storagePath;

    @TableField("login_timeout")
    private Integer loginTimeout;

    @TableField("session_timeout")
    private Integer sessionTimeout;

    @TableField("date_format")
    private String dateFormat;

    @TableField("page_size")
    private Integer pageSize;

    @TableField("smtp_server")
    private String smtpServer;

    @TableField("email_account")
    private String emailAccount;

    @TableField("email_password")
    private String emailPassword;

    @TableField("remarks")
    private String remarks;
}