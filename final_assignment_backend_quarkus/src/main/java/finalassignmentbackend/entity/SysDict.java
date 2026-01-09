package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 数据字典表实体类，对应数据库??"sys_dict"
 * 用于系统数据字典的配置和管理
 */
@Data
@TableName("sys_dict")
public class SysDict implements Serializable {
    /**
     * 序列化版??UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 字典 ID，主键，自动增长
     */
    @TableId(value = "dict_id", type = IdType.AUTO)
    private Integer dictId;

    /**
     * 父字??ID (0表示顶级)
     */
    @TableField("parent_id")
    private Integer parentId;

    /**
     * 字典类型
     */
    @TableField("dict_type")
    private String dictType;

    /**
     * 字典编码
     */
    @TableField("dict_code")
    private String dictCode;

    /**
     * 字典标签
     */
    @TableField("dict_label")
    private String dictLabel;

    /**
     * 字典??
     */
    @TableField("dict_value")
    private String dictValue;

    /**
     * 字典描述
     */
    @TableField("dict_description")
    private String dictDescription;

    /**
     * CSS类名
     */
    @TableField("css_class")
    private String cssClass;

    /**
     * 列表样式
     */
    @TableField("list_class")
    private String listClass;

    /**
     * 是否默认 (1=?? 0=??
     */
    @TableField("is_default")
    private Boolean isDefault;

    /**
     * 是否固定 (1=?? 0=??
     */
    @TableField("is_fixed")
    private Boolean isFixed;

    /**
     * 状??(Active, Inactive)
     */
    @TableField("status")
    private String status;

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
     * 创建??
     */
    @TableField("created_by")
    private String createdBy;

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
