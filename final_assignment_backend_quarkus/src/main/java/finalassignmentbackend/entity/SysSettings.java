package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 系统设置表实体类，对应数据库??"sys_settings"
 * 用于存储系统级别的配置参??
 */
@Data
@TableName("sys_settings")
public class SysSettings implements Serializable {
    /**
     * 序列化版??UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 设置 ID，主键，自动增长
     */
    @TableId(value = "setting_id", type = IdType.AUTO)
    private Integer settingId;

    /**
     * 设置??
     */
    @TableField("setting_key")
    private String settingKey;

    /**
     * 设置??
     */
    @TableField("setting_value")
    private String settingValue;

    /**
     * 设置类型 (String, Number, Boolean, JSON)
     */
    @TableField("setting_type")
    private String settingType;

    /**
     * 设置分类
     */
    @TableField("category")
    private String category;

    /**
     * 设置描述
     */
    @TableField("description")
    private String description;

    /**
     * 是否加密 (1=?? 0=??
     */
    @TableField("is_encrypted")
    private Boolean isEncrypted;

    /**
     * 是否可编??(1=?? 0=??
     */
    @TableField("is_editable")
    private Boolean isEditable;

    /**
     * 排序
     */
    @TableField("sort_order")
    private Integer sortOrder;

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
     * 更新??
     */
    @TableField("updated_by")
    private String updatedBy;

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
