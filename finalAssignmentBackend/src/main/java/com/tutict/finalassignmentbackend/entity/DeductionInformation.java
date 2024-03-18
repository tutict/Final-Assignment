package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("deduction_information")
public class DeductionInformation {

    private int offenseId;
    private int deductedPoints;
    private Date deductionTime;
    private String handler;
    private String approver;
    private String remarks;
}
