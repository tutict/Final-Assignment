package com.tutict.finalassignmentcloud.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 驾驶员信息实体类，对应数据库表"driver_information"
 * 包含驾驶员的基本信息以及驾驶证相关信息
 */
@Data
@TableName("driver_information")
public class DriverInformation implements Serializable {
    /**
     * 序列化版本UID，用于对象序列化
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 驾驶员 ID，主键，自动生成
     */
    @TableId(value = "driver_id", type = IdType.AUTO)
    private Long driverId;

    /**
     * 姓名
     */
    @TableField("name")
    private String name;

    /**
     * 身份证号码
     */
    @TableField("id_card_number")
    private String idCardNumber;

    /**
     * 性别 (Male, Female)
     */
    @TableField("gender")
    private String gender;

    /**
     * 出生日期
     */
    @TableField("birthdate")
    private LocalDate birthdate;

    /**
     * 联系电话
     */
    @TableField("contact_number")
    private String contactNumber;

    /**
     * 电子邮箱
     */
    @TableField("email")
    private String email;

    /**
     * 联系地址
     */
    @TableField("address")
    private String address;

    /**
     * 驾驶证号码
     */
    @TableField("driver_license_number")
    private String driverLicenseNumber;

    /**
     * 准驾车型 (A1, A2, B1, B2, C1, C2等)
     */
    @TableField("license_type")
    private String licenseType;

    /**
     * 首次领取驾驶证日期
     */
    @TableField("first_license_date")
    private LocalDate firstLicenseDate;

    /**
     * 驾驶证签发日期
     */
    @TableField("issue_date")
    private LocalDate issueDate;

    /**
     * 驾驶证有效期截止日期
     */
    @TableField("expiry_date")
    private LocalDate expiryDate;

    /**
     * 发证机关
     */
    @TableField("issuing_authority")
    private String issuingAuthority;

    /**
     * 当前积分 (满分12分)
     */
    @TableField("current_points")
    private Integer currentPoints;

    /**
     * 累计扣分
     */
    @TableField("total_deducted_points")
    private Integer totalDeductedPoints;

    /**
     * 驾驶证状态(Active, Suspended, Revoked, Expired)
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
     * 创建人
     */
    @TableField("created_by")
    private String createdBy;

    /**
     * 更新人
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

