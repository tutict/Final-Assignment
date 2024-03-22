package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("deduction_information")
public class DeductionInformation implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableField("offense_id")
    private Integer offenseId;

    @TableField("deducted_points")
    private Integer deductedPoints;

    @TableField("deduction_time")
    private LocalDateTime deductionTime;

    @TableField("handler")
    private String handler;

    @TableField("approver")
    private String approver;

    @TableField("remarks")
    private String remarks;
}
