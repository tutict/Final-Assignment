package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 权限管理实体类
 * 该类用于映射数据库中的permission_management表，用于权限管理
 */
@Data
@TableName("permission_management")
public class PermissionManagement implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 权限ID，主键
     * 该字段映射permission_id，使用自动增长方式生成ID
     */
    @TableId(value = "permission_id", type = IdType.AUTO)
    private Integer permissionId;

    /**
     * 权限名称
     * 该字段映射permission_name
     */
    @TableField("permission_name")
    private String permissionName;

    /**
     * 权限描述
     * 该字段映射permission_description
     */
    @TableField("permission_description")
    private String permissionDescription;

    /**
     * 创建时间
     * 该字段映射created_time
     */
    @TableField("created_time")
    private LocalDateTime createdTime;

    /**
     * 修改时间
     * 该字段映射modified_time
     */
    @TableField("modified_time")
    private LocalDateTime modifiedTime;

    /**
     * 备注信息
     * 该字段映射remarks
     */
    @TableField("remarks")
    private String remarks;


    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;
}