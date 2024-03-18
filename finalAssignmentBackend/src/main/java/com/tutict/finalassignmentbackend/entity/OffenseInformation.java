package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("offense_information")
public class OffenseInformation {

    private int offenseId;
    private Date offenseTime;
    private String offenseLocation;
    private String licensePlate;
    private String driverName;
    private String offenseType;
    private String offenseCode;
    private double fineAmount;
    private int deductedPoints;
    private String processStatus;
    private String processResult;
}
