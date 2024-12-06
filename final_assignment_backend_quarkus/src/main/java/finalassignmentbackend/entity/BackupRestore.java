package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 备份与恢复实体类
 * 该类用于在数据库中表示备份与恢复操作的相关信息，包括备份文件名、备份时间、恢复时间、恢复状态及备注
 */
@Data
@TableName("backup_restore")
public class BackupRestore implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 备份ID
     * 使用自动增长类型作为主键
     */
    @TableId(value = "backup_id", type = IdType.AUTO)
    private Integer backupId;

    /**
     * 备份文件名
     * 记录备份文件的名称
     */
    @TableField("backup_file_name")
    private String backupFileName;

    /**
     * 备份时间
     * 记录执行备份操作的时间
     */
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @TableField("backup_time")
    private LocalDateTime backupTime;

    /**
     * 恢复时间
     * 记录执行恢复操作的时间
     */
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @TableField("restore_time")
    private LocalDateTime restoreTime;

    /**
     * 恢复状态
     * 描述备份文件恢复操作的状态
     */
    @TableField("restore_status")
    private String restoreStatus;

    /**
     * 备注
     * 记录关于备份与恢复操作的额外信息
     */
    @TableField("remarks")
    private String remarks;
}
