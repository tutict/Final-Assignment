package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 驾驶员信息实体类，对应数据库表 "driver_information"
 * 包含驾驶员的基本信息以及驾驶证相关信息
 */
@Data
@TableName("driver_information")
public class DriverInformation implements Serializable {
    /**
     * 序列化版本 UID，用于对象序列化
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 驾驶员 ID，主键，自动生成
     */
    @TableId(value = "driver_id", type = IdType.AUTO)
    private Integer driverId;

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
     * 联系电话
     */
    @TableField("contact_number")
    private String contactNumber;

    /**
     * 驾驶证号码
     */
    @TableField("driver_license_number")
    private String driverLicenseNumber;

    /**
     * 性别
     */
    @TableField("gender")
    private String gender;

    /**
     * 出生日期
     */
    @TableField("birthdate")
    private LocalDate birthdate;

    /**
     * 首次领取驾驶证日期
     */
    @TableField("first_license_date")
    private LocalDate firstLicenseDate;

    /**
     * 允许驾驶的车辆类型
     */
    @TableField("allowed_vehicle_type")
    private String allowedVehicleType;

    /**
     * 驾驶证发证日期
     */
    @TableField("issue_date")
    private LocalDate issueDate;

    /**
     * 驾驶证有效期截止日期
     */
    @TableField("expiry_date")
    private LocalDate expiryDate;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;
}
