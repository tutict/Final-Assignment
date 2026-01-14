package com.tutict.finalassignmentcloud.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 备份恢复表实体类，对应数据库表"sys_backup_restore"
 * 用于记录系统的备份和恢复操作
 */
@Data
@TableName("sys_backup_restore")
public class SysBackupRestore implements Serializable {
    /**
     * 序列化版本UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 备份 ID，主键，自动增长
     */
    @TableId(value = "backup_id", type = IdType.AUTO)
    private Long backupId;

    /**
     * 备份类型 (Full, Incremental, Differential)
     */
    @TableField("backup_type")
    private String backupType;

    /**
     * 备份文件名
     */
    @TableField("backup_file_name")
    private String backupFileName;

    /**
     * 备份文件路径
     */
    @TableField("backup_file_path")
    private String backupFilePath;

    /**
     * 备份文件大小 (字节)
     */
    @TableField("backup_file_size")
    private Long backupFileSize;

    /**
     * 备份时间
     */
    @TableField("backup_time")
    private LocalDateTime backupTime;

    /**
     * 备份耗时 (秒)
     */
    @TableField("backup_duration")
    private Integer backupDuration;

    /**
     * 备份操作人
     */
    @TableField("backup_handler")
    private String backupHandler;

    /**
     * 恢复时间
     */
    @TableField("restore_time")
    private LocalDateTime restoreTime;

    /**
     * 恢复耗时 (秒)
     */
    @TableField("restore_duration")
    private Integer restoreDuration;

    /**
     * 恢复状态(Success, Failed, Partial)
     */
    @TableField("restore_status")
    private String restoreStatus;

    /**
     * 恢复操作人
     */
    @TableField("restore_handler")
    private String restoreHandler;

    /**
     * 错误信息
     */
    @TableField("error_message")
    private String errorMessage;

    /**
     * 备份状态(Success, Failed, In_Progress)
     */
    @TableField("status")
    private String status;

    /**
     * 创建时间
     */
    @TableField(value = "created_at", fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    /**
     * 更新时间
     */
    @TableField(value = "updated_at", fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;

    /**
     * 备注
     */
    @TableField("remarks")
    private String remarks;
}

