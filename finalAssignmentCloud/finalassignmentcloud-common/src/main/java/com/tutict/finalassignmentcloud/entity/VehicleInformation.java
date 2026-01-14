package com.tutict.finalassignmentcloud.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 车辆信息实体类，对应数据库表 "vehicle_information"
 * 包含车辆的基本信息及其所有者信息
 */
@Data
@TableName("vehicle_information")
public class VehicleInformation implements Serializable {
    /**
     * 序列化版本UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 车辆 ID，主键，自动增长
     */
    @TableId(value = "vehicle_id", type = IdType.AUTO)
    private Long vehicleId;

    /**
     * 车牌号
     */
    @TableField("license_plate")
    private String licensePlate;

    /**
     * 车牌颜色 (Blue, Yellow, Black, White, Green)
     */
    @TableField("plate_color")
    private String plateColor;

    /**
     * 车辆类型
     */
    @TableField("vehicle_type")
    private String vehicleType;

    /**
     * 品牌
     */
    @TableField("brand")
    private String brand;

    /**
     * 型号
     */
    @TableField("model")
    private String model;

    /**
     * 车身颜色
     */
    @TableField("vehicle_color")
    private String vehicleColor;

    /**
     * 发动机号
     */
    @TableField("engine_number")
    private String engineNumber;

    /**
     * 车架号 (VIN)
     */
    @TableField("frame_number")
    private String frameNumber;

    /**
     * 车主姓名
     */
    @TableField("owner_name")
    private String ownerName;

    /**
     * 车主身份证号
     */
    @TableField("owner_id_card")
    private String ownerIdCard;

    /**
     * 车主联系电话
     */
    @TableField("owner_contact")
    private String ownerContact;

    /**
     * 车主地址
     */
    @TableField("owner_address")
    private String ownerAddress;

    /**
     * 初次登记日期
     */
    @TableField("first_registration_date")
    private LocalDate firstRegistrationDate;

    /**
     * 注册登记日期
     */
    @TableField("registration_date")
    private LocalDate registrationDate;

    /**
     * 发证机关
     */
    @TableField("issuing_authority")
    private String issuingAuthority;

    /**
     * 车辆状态(Active, Inactive, Scrapped, Stolen, Mortgaged)
     */
    @TableField("status")
    private String status;

    /**
     * 年检到期日期
     */
    @TableField("inspection_expiry_date")
    private LocalDate inspectionExpiryDate;

    /**
     * 保险到期日期
     */
    @TableField("insurance_expiry_date")
    private LocalDate insuranceExpiryDate;

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

