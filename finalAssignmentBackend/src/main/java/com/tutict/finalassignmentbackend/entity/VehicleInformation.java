package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDate;

/**
 * 车辆信息实体类
 * 包含车辆的基本信息及其所有者信息
 */
@Data
@TableName("vehicle_information")
public class VehicleInformation implements Serializable {
    /**
     * 序列化版本 UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 车辆 ID，主键，自动增长
     */
    @TableId(value = "vehicle_id", type = IdType.AUTO)
    private Integer vehicleId;

    /**
     * 车牌号
     */
    @TableField("license_plate")
    private String licensePlate;

    /**
     * 车辆类型
     */
    @TableField("vehicle_type")
    private String vehicleType;

    /**
     * 车主姓名
     */
    @TableField("owner_name")
    private String ownerName;

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
     * 发动机号
     */
    @TableField("engine_number")
    private String engineNumber;

    /**
     * 车架号
     */
    @TableField("frame_number")
    private String frameNumber;

    /**
     * 车身颜色
     */
    @TableField("vehicle_color")
    private String vehicleColor;

    /**
     * 首次注册日期
     */
    @TableField("first_registration_date")
    private LocalDate firstRegistrationDate;

    /**
     * 当前状态
     */
    @TableField("current_status")
    private String currentStatus;
}
