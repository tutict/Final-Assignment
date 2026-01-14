package com.tutict.finalassignmentcloud.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 驾驶员车辆关联表实体类，对应数据库表"driver_vehicle"
 * 多对多关系表，用于记录驾驶员和车辆之间的关联关系
 */
@Data
@TableName("driver_vehicle")
public class DriverVehicle implements Serializable {
    /**
     * 序列化版本UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 关联 ID，主键，自动增长
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 驾驶员 ID
     */
    @TableField("driver_id")
    private Long driverId;

    /**
     * 车辆 ID
     */
    @TableField("vehicle_id")
    private Long vehicleId;

    /**
     * 关系类型 (Owner, Family, Borrower, Other)
     */
    @TableField("relationship")
    private String relationship;

    /**
     * 是否主要使用 (1=是 0=否)
     */
    @TableField("is_primary")
    private Boolean isPrimary;

    /**
     * 绑定日期
     */
    @TableField("bind_date")
    private LocalDate bindDate;

    /**
     * 解绑日期
     */
    @TableField("unbind_date")
    private LocalDate unbindDate;

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

