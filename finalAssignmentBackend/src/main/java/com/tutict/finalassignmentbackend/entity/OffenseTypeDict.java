package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 违法类型字典表实体类，对应数据库表 "offense_type_dict"
 * 用于定义各种违法类型及其对应的处罚标准
 */
@Data
@TableName("offense_type_dict")
public class OffenseTypeDict implements Serializable {
    /**
     * 序列化版本 UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 类型 ID，主键，自动增长
     */
    @TableId(value = "type_id", type = IdType.AUTO)
    private Integer typeId;

    /**
     * 违法代码
     */
    @TableField("offense_code")
    private String offenseCode;

    /**
     * 违法名称
     */
    @TableField("offense_name")
    private String offenseName;

    /**
     * 违法类别 (超速, 闯红灯, 酒驾, 毒驾等)
     */
    @TableField("category")
    private String category;

    /**
     * 违法描述
     */
    @TableField("description")
    private String description;

    /**
     * 标准罚款金额 (元)
     */
    @TableField("standard_fine_amount")
    private BigDecimal standardFineAmount;

    /**
     * 最低罚款金额 (元)
     */
    @TableField("min_fine_amount")
    private BigDecimal minFineAmount;

    /**
     * 最高罚款金额 (元)
     */
    @TableField("max_fine_amount")
    private BigDecimal maxFineAmount;

    /**
     * 扣分 (0-12分)
     */
    @TableField("deducted_points")
    private Integer deductedPoints;

    /**
     * 拘留天数
     */
    @TableField("detention_days")
    private Integer detentionDays;

    /**
     * 吊销驾照天数
     */
    @TableField("license_suspension_days")
    private Integer licenseSuspensionDays;

    /**
     * 严重程度 (Minor, Moderate, Severe, Critical)
     */
    @TableField("severity_level")
    private String severityLevel;

    /**
     * 法律依据
     */
    @TableField("legal_basis")
    private String legalBasis;

    /**
     * 状态 (Active, Inactive)
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