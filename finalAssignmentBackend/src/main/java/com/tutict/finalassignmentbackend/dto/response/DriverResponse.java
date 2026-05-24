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
    private String licenseNumber;
    private String phoneNumber;
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
                .licenseNumber(driver.getDriverLicenseNumber())
                .phoneNumber(driver.getContactNumber())
                .birthdate(driver.getBirthdate())
                .firstLicenseDate(driver.getFirstLicenseDate())
                .issueDate(driver.getIssueDate())
                .expiryDate(driver.getExpiryDate())
                .build();
    }
}
