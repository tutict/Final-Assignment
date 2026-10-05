package com.tutict.finalassignmentbackend.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;

@Data
public class DriverCreateRequest {

    @NotBlank(message = "请填写姓名")
    private String name;

    private String idCardNumber;

    private String gender;

    @NotBlank(message = "请填写驾驶证号")
    @JsonAlias("driverLicenseNumber")
    private String licenseNumber;

    @JsonAlias("contactNumber")
    private String phoneNumber;

    private String email;

    private String address;

    private String licenseType;

    @JsonAlias("allowedVehicleType")
    private String allowedVehicleType;

    private String issuingAuthority;

    private String status;

    private String remarks;

    @NotNull(message = "Birthdate is required")
    private LocalDate birthdate;

    @NotNull(message = "First license date is required")
    private LocalDate firstLicenseDate;

    @NotNull(message = "Issue date is required")
    private LocalDate issueDate;

    @NotNull(message = "Expiry date is required")
    private LocalDate expiryDate;

    public com.tutict.finalassignmentbackend.entity.driver.DriverInformation toEntity() {
        com.tutict.finalassignmentbackend.entity.driver.DriverInformation driver =
                new com.tutict.finalassignmentbackend.entity.driver.DriverInformation();
        driver.setName(name);
        driver.setIdCardNumber(blankToNull(idCardNumber));
        driver.setGender(blankToNull(gender));
        driver.setDriverLicenseNumber(licenseNumber);
        driver.setContactNumber(blankToNull(phoneNumber));
        driver.setEmail(blankToNull(email));
        driver.setAddress(blankToNull(address));
        String resolvedLicenseType = blankToNull(licenseType);
        if (resolvedLicenseType == null) {
            resolvedLicenseType = blankToNull(allowedVehicleType);
        }
        driver.setLicenseType(resolvedLicenseType);
        driver.setIssuingAuthority(blankToNull(issuingAuthority));
        driver.setStatus(blankToNull(status));
        driver.setRemarks(blankToNull(remarks));
        driver.setBirthdate(birthdate);
        driver.setFirstLicenseDate(firstLicenseDate);
        driver.setIssueDate(issueDate);
        driver.setExpiryDate(expiryDate);
        return driver;
    }

    private static String blankToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
