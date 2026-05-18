package com.tutict.finalassignmentbackend.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;

@Data
public class DriverCreateRequest {

    @NotBlank(message = "Name is required")
    private String name;

    @NotBlank(message = "License number is required")
    private String licenseNumber;

    private String phoneNumber;

    @NotNull(message = "Birthdate is required")
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate birthdate;

    @NotNull(message = "First license date is required")
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate firstLicenseDate;

    @NotNull(message = "Issue date is required")
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate issueDate;

    @NotNull(message = "Expiry date is required")
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate expiryDate;

    public com.tutict.finalassignmentbackend.entity.DriverInformation toEntity() {
        com.tutict.finalassignmentbackend.entity.DriverInformation driver =
                new com.tutict.finalassignmentbackend.entity.DriverInformation();
        driver.setName(name);
        driver.setDriverLicenseNumber(licenseNumber);
        driver.setContactNumber(phoneNumber);
        driver.setBirthdate(birthdate);
        driver.setFirstLicenseDate(firstLicenseDate);
        driver.setIssueDate(issueDate);
        driver.setExpiryDate(expiryDate);
        return driver;
    }
}
