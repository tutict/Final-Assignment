package com.tutict.finalassignmentbackend.dto.response;

import com.tutict.finalassignmentbackend.entity.driver.DriverInformation;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;

@Data
@Builder
public class DriverResponse {

    private Long driverId;
    private Long authUserId;
    private String name;
    private String idCardNumber;
    private String gender;
    private String licenseNumber;
    private String driverLicenseNumber;
    private String phoneNumber;
    private String contactNumber;
    private String email;
    private String address;
    private String licenseType;
    private String issuingAuthority;
    private String status;
    private String remarks;
    private LocalDate birthdate;
    private LocalDate firstLicenseDate;
    private LocalDate issueDate;
    private LocalDate expiryDate;

    public static DriverResponse from(DriverInformation driver) {
        if (driver == null) {
            return null;
        }
        return DriverResponse.builder()
                .driverId(driver.getDriverId())
                .authUserId(driver.getAuthUserId())
                .name(driver.getName())
                .idCardNumber(driver.getIdCardNumber())
                .gender(driver.getGender())
                .licenseNumber(driver.getDriverLicenseNumber())
                .driverLicenseNumber(driver.getDriverLicenseNumber())
                .phoneNumber(driver.getContactNumber())
                .contactNumber(driver.getContactNumber())
                .email(driver.getEmail())
                .address(driver.getAddress())
                .licenseType(driver.getLicenseType())
                .issuingAuthority(driver.getIssuingAuthority())
                .status(driver.getStatus())
                .remarks(driver.getRemarks())
                .birthdate(driver.getBirthdate())
                .firstLicenseDate(driver.getFirstLicenseDate())
                .issueDate(driver.getIssueDate())
                .expiryDate(driver.getExpiryDate())
                .build();
    }
}
