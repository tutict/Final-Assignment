package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDate;

@Data
@TableName("driver_information")
public class DriverInformation implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "driver_id", type = IdType.AUTO)
    private Integer driverId;

    @TableField("name")
    private String name;

    @TableField("id_card_number")
    private String idCardNumber;

    @TableField("contact_number")
    private String contactNumber;

    @TableField("driver_license_number")
    private String driverLicenseNumber;

    @TableField("gender")
    private String gender;

    @TableField("birthdate")
    private LocalDate birthdate;

    @TableField("first_license_date")
    private LocalDate firstLicenseDate;

    @TableField("allowed_vehicle_type")
    private String allowedVehicleType;

    @TableField("issue_date")
    private LocalDate issueDate;

    @TableField("expiry_date")
    private LocalDate expiryDate;
}