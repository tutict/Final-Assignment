package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("offense_information")
public class OffenseInformation implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "offense_id", type = IdType.AUTO)
    private Integer offenseId;

    @TableField("offense_time")
    private LocalDateTime offenseTime;

    @TableField("offense_location")
    private String offenseLocation;

    @TableField("license_plate")
    private String licensePlate;

    @TableField("driver_name")
    private String driverName;

    @TableField("offense_type")
    private String offenseType;

    @TableField("offense_code")
    private String offenseCode;

    @TableField("fine_amount")
    private BigDecimal fineAmount;

    @TableField("deducted_points")
    private Integer deductedPoints;

    @TableField("process_status")
    private String processStatus;

    @TableField("process_result")
    private String processResult;
}