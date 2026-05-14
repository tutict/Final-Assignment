package com.tutict.finalassignmentbackend.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class AppealCreateRequest {

    @NotNull(message = "offenseId must not be null")
    @Positive(message = "offenseId must be greater than zero")
    private Long offenseId;

    @Size(max = 64, message = "appealNumber must not exceed 64 characters")
    private String appealNumber;

    @NotBlank(message = "appellantName must not be blank")
    @Size(max = 100, message = "appellantName must not exceed 100 characters")
    private String appellantName;

    @NotBlank(message = "appellantIdCard must not be blank")
    @Pattern(regexp = "(^\\d{15}$)|(^\\d{17}[0-9Xx]$)", message = "appellantIdCard format is invalid")
    private String appellantIdCard;

    @NotBlank(message = "appellantContact must not be blank")
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "appellantContact format is invalid")
    private String appellantContact;

    @Email(message = "appellantEmail format is invalid")
    @Size(max = 100, message = "appellantEmail must not exceed 100 characters")
    private String appellantEmail;

    @Size(max = 255, message = "appellantAddress must not exceed 255 characters")
    private String appellantAddress;

    @NotBlank(message = "appealType must not be blank")
    @Size(max = 100, message = "appealType must not exceed 100 characters")
    private String appealType;

    @NotBlank(message = "appealReason must not be blank")
    @Size(max = 1000, message = "appealReason must not exceed 1000 characters")
    private String appealReason;

    @NotNull(message = "appealTime must not be null")
    @PastOrPresent(message = "appealTime must not be in the future")
    private LocalDateTime appealTime;

    @Size(max = 1000, message = "evidenceDescription must not exceed 1000 characters")
    private String evidenceDescription;

    @Size(max = 2000, message = "evidenceUrls must not exceed 2000 characters")
    private String evidenceUrls;

    @Size(max = 50, message = "acceptanceStatus must not exceed 50 characters")
    private String acceptanceStatus;

    @PastOrPresent(message = "acceptanceTime must not be in the future")
    private LocalDateTime acceptanceTime;

    @Size(max = 100, message = "acceptanceHandler must not exceed 100 characters")
    private String acceptanceHandler;

    @Size(max = 1000, message = "rejectionReason must not exceed 1000 characters")
    private String rejectionReason;

    @Size(max = 50, message = "processStatus must not exceed 50 characters")
    private String processStatus;

    @PastOrPresent(message = "processTime must not be in the future")
    private LocalDateTime processTime;

    @Size(max = 1000, message = "processResult must not exceed 1000 characters")
    private String processResult;

    @Size(max = 100, message = "processHandler must not exceed 100 characters")
    private String processHandler;

    @Size(max = 100, message = "createdBy must not exceed 100 characters")
    private String createdBy;

    @Size(max = 100, message = "updatedBy must not exceed 100 characters")
    private String updatedBy;

    @Size(max = 1000, message = "remarks must not exceed 1000 characters")
    private String remarks;
}
