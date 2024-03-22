package com.tutict.finalassignmentbackend.entity.view;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("offense_details")
public class OffenseDetails implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "offense_id")
    private Integer offenseId;

    @TableField("offense_time")
    private LocalDateTime offenseTime;

    @TableField("offense_location")
    private String offenseLocation;

    @TableField("offense_type")
    private String offenseType;

    @TableField("offense_code")
    private String offenseCode;

    @TableField("driver_name")
    private String driverName;

    @TableField("driver_id_card_number")
    private String driverIdCardNumber;

    @TableField("license_plate")
    private String licensePlate;

    @TableField("vehicle_type")
    private String vehicleType;

    @TableField("owner_name")
    private String ownerName;

    // 默认构造函数
    public OffenseDetails() {}

    // 带参构造函数
    public OffenseDetails(Integer offenseId, LocalDateTime offenseTime, String offenseLocation,
                          String offenseType, String offenseCode, String driverName,
                          String driverIdCardNumber, String licensePlate, String vehicleType,
                          String ownerName) {
        this.offenseId = offenseId;
        this.offenseTime = offenseTime;
        this.offenseLocation = offenseLocation;
        this.offenseType = offenseType;
        this.offenseCode = offenseCode;
        this.driverName = driverName;
        this.driverIdCardNumber = driverIdCardNumber;
        this.licensePlate = licensePlate;
        this.vehicleType = vehicleType;
        this.ownerName = ownerName;
    }
}