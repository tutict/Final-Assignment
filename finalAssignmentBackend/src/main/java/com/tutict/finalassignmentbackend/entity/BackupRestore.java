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
@TableName("backup_restore")
public class BackupRestore implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "backup_id", type = IdType.AUTO)
    private Integer backupId;

    @TableField("backup_file_name")
    private String backupFileName;

    @TableField("backup_time")
    private LocalDateTime backupTime;

    @TableField("restore_time")
    private LocalDateTime restoreTime;

    @TableField("restore_status")
    private String restoreStatus;

    @TableField("remarks")
    private String remarks;
}
