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

// 进行违规信息的实体类，包含违规相关的各种属性
@Data
@TableName("offense_information")
public class OffenseInformation implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    // 违规ID，自动增长
    @TableId(value = "offense_id", type = IdType.AUTO)
    private Integer offenseId;

    // 违规时间
    @TableField("offense_time")
    private LocalDateTime offenseTime;

    // 违规地点
    @TableField("offense_location")
    private String offenseLocation;

    // 车牌号
    @TableField("license_plate")
    private String licensePlate;

    // 司机姓名
    @TableField("driver_name")
    private String driverName;

    // 违规类型
    @TableField("offense_type")
    private String offenseType;

    // 违规代码
    @TableField("offense_code")
    private String offenseCode;

    // 罚款金额
    @TableField("fine_amount")
    private BigDecimal fineAmount;

    // 扣分
    @TableField("deducted_points")
    private Integer deductedPoints;

    // 处理状态
    @TableField("process_status")
    private String processStatus;

    // 处理结果
    @TableField("process_result")
    private String processResult;
}
