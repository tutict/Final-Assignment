package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("vehicle_information")
public class VehicleInformation {

    private int vehicleId;
    private String licensePlate;
    private String vehicleType;
    private String ownerName;
    private String idCardNumber;
    private String contactNumber;
    private String engineNumber;
    private String frameNumber;
    private String vehicleColor;
    private Date firstRegistrationDate;
    private String currentStatus;
}
