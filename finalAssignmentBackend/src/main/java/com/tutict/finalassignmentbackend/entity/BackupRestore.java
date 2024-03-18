package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("backup_restore")
public class BackupRestore {

    private int backupId;
    private String backupFileName;
    private Date backupTime;
    private Date restoreTime;
    private String restoreStatus;
    private String remarks;

}
