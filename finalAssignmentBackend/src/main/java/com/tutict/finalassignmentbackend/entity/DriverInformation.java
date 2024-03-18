package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("driver_information")
public class DriverInformation {

    private int driverId;
    private String name;
    private String idCardNumber;
    private String contactNumber;
    private String driverLicenseNumber;
    private String gender;
    private Date birthdate;
    private Date firstLicenseDate;
    private String allowedVehicleType;
    private Date issueDate;
    private Date expiryDate;
}
