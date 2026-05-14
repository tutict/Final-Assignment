package com.tutict.finalassignmentbackend.dto.request;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class OffenseCreateRequest {

    @NotBlank(message = "offenseCode must not be blank")
    @Size(max = 50, message = "offenseCode must not exceed 50 characters")
    private String offenseCode;

    @Size(max = 64, message = "offenseNumber must not exceed 64 characters")
    private String offenseNumber;

    @NotNull(message = "offenseTime must not be null")
    @PastOrPresent(message = "offenseTime must not be in the future")
    private LocalDateTime offenseTime;

    @NotBlank(message = "offenseLocation must not be blank")
    @Size(max = 255, message = "offenseLocation must not exceed 255 characters")
    private String offenseLocation;

    @Size(max = 64, message = "offenseProvince must not exceed 64 characters")
    private String offenseProvince;

    @Size(max = 64, message = "offenseCity must not exceed 64 characters")
    private String offenseCity;

    @NotNull(message = "driverId must not be null")
    @Positive(message = "driverId must be greater than zero")
    private Long driverId;

    @NotNull(message = "vehicleId must not be null")
    @Positive(message = "vehicleId must be greater than zero")
    private Long vehicleId;

    @Size(max = 1000, message = "offenseDescription must not exceed 1000 characters")
    private String offenseDescription;

    @Size(max = 50, message = "evidenceType must not exceed 50 characters")
    private String evidenceType;

    @Size(max = 2000, message = "evidenceUrls must not exceed 2000 characters")
    private String evidenceUrls;

    @Size(max = 100, message = "enforcementAgency must not exceed 100 characters")
    private String enforcementAgency;

    @Size(max = 100, message = "enforcementOfficer must not exceed 100 characters")
    private String enforcementOfficer;

    @Size(max = 100, message = "enforcementDevice must not exceed 100 characters")
    private String enforcementDevice;

    @Size(max = 50, message = "processStatus must not exceed 50 characters")
    private String processStatus;

    @Size(max = 50, message = "notificationStatus must not exceed 50 characters")
    private String notificationStatus;

    @PastOrPresent(message = "notificationTime must not be in the future")
    private LocalDateTime notificationTime;

    @DecimalMin(value = "0.0", message = "fineAmount must not be negative")
    @DecimalMax(value = "100000.0", message = "fineAmount must not exceed 100000")
    private BigDecimal fineAmount;

    @Min(value = 0, message = "deductedPoints must not be negative")
    @Max(value = 12, message = "deductedPoints must not exceed 12")
    private Integer deductedPoints;

    @Min(value = 0, message = "detentionDays must not be negative")
    @Max(value = 365, message = "detentionDays must not exceed 365")
    private Integer detentionDays;

    @PastOrPresent(message = "processTime must not be in the future")
    private LocalDateTime processTime;

    @Size(max = 100, message = "processHandler must not exceed 100 characters")
    private String processHandler;

    @Size(max = 1000, message = "processResult must not exceed 1000 characters")
    private String processResult;

    @Size(max = 100, message = "createdBy must not exceed 100 characters")
    private String createdBy;

    @Size(max = 100, message = "updatedBy must not exceed 100 characters")
    private String updatedBy;

    @Size(max = 1000, message = "remarks must not exceed 1000 characters")
    private String remarks;
}
