package com.tutict.finalassignmentbackend.entity.view;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 违章详情实体类
 * 包含违章记录的相关信息，如违章ID、时间、地点、类型等。
 * 实现了 Serializable 接口，支持序列化。
 */
@Data
@TableName("offense_details")
public class OffenseDetails implements Serializable {
    /**
     * 序列化版本UID，用于对象序列化和反序列化。
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 违章ID，对应数据库表中的 "offense_id" 列。
     */
    @TableId(value = "offense_id")
    private Integer offenseId;

    /**
     * 违章时间，对应数据库表中的 "offense_time" 列。
     */
    @TableField("offense_time")
    private LocalDateTime offenseTime;

    /**
     * 违章地点，对应数据库表中的 "offense_location" 列。
     */
    @TableField("offense_location")
    private String offenseLocation;

    /**
     * 违章类型，对应数据库表中的 "offense_type" 列。
     */
    @TableField("offense_type")
    private String offenseType;

    /**
     * 违章代码，对应数据库表中的 "offense_code" 列。
     */
    @TableField("offense_code")
    private String offenseCode;

    /**
     * 驾驶员姓名，对应数据库表中的 "driver_name" 列。
     */
    @TableField("driver_name")
    private String driverName;

    /**
     * 驾驶员身份证号，对应数据库表中的 "driver_id_card_number" 列。
     */
    @TableField("driver_id_card_number")
    private String driverIdCardNumber;

    /**
     * 车牌号，对应数据库表中的 "license_plate" 列。
     */
    @TableField("license_plate")
    private String licensePlate;

    /**
     * 车辆类型，对应数据库表中的 "vehicle_type" 列。
     */
    @TableField("vehicle_type")
    private String vehicleType;

    /**
     * 车主姓名，对应数据库表中的 "owner_name" 列。
     */
    @TableField("owner_name")
    private String ownerName;

    /**
     * 带参数的构造函数。
     *
     * @param offenseId 违章ID
     * @param offenseTime 违章时间
     * @param offenseLocation 违章地点
     * @param offenseType 违章类型
     * @param offenseCode 违章代码
     * @param driverName 驾驶员姓名
     * @param driverIdCardNumber 驾驶员身份证号
     * @param licensePlate 车牌号
     * @param vehicleType 车辆类型
     * @param ownerName 车主姓名
     */
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
