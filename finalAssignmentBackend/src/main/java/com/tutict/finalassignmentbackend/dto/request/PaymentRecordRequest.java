package com.tutict.finalassignmentbackend.dto.request;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class PaymentRecordRequest {

    @NotNull(message = "fineId must not be null")
    @Positive(message = "fineId must be greater than zero")
    private Long fineId;

    @Size(max = 64, message = "paymentNumber must not exceed 64 characters")
    private String paymentNumber;

    @NotNull(message = "paymentAmount must not be null")
    @DecimalMin(value = "0.0", message = "paymentAmount must not be negative")
    @DecimalMax(value = "100000.0", message = "paymentAmount must not exceed 100000")
    private BigDecimal paymentAmount;

    @NotBlank(message = "paymentMethod must not be blank")
    @Size(max = 50, message = "paymentMethod must not exceed 50 characters")
    private String paymentMethod;

    @PastOrPresent(message = "paymentTime must not be in the future")
    private LocalDateTime paymentTime;

    @Size(max = 50, message = "paymentChannel must not exceed 50 characters")
    private String paymentChannel;

    @NotBlank(message = "payerName must not be blank")
    @Size(max = 100, message = "payerName must not exceed 100 characters")
    private String payerName;

    @Pattern(regexp = "(^\\d{15}$)|(^\\d{17}[0-9Xx]$)", message = "payerIdCard format is invalid")
    private String payerIdCard;

    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "payerContact format is invalid")
    private String payerContact;

    @Size(max = 100, message = "bankName must not exceed 100 characters")
    private String bankName;

    @Size(max = 64, message = "bankAccount must not exceed 64 characters")
    private String bankAccount;

    @Size(max = 128, message = "transactionId must not exceed 128 characters")
    private String transactionId;

    @Size(max = 128, message = "receiptNumber must not exceed 128 characters")
    private String receiptNumber;

    @Size(max = 500, message = "receiptUrl must not exceed 500 characters")
    private String receiptUrl;

    @Size(max = 50, message = "paymentStatus must not exceed 50 characters")
    private String paymentStatus;

    @PositiveOrZero(message = "version must not be negative")
    private Integer version;

    @DecimalMin(value = "0.0", message = "refundAmount must not be negative")
    @DecimalMax(value = "100000.0", message = "refundAmount must not exceed 100000")
    private BigDecimal refundAmount;

    @PastOrPresent(message = "refundTime must not be in the future")
    private LocalDateTime refundTime;

    @Size(max = 100, message = "createdBy must not exceed 100 characters")
    private String createdBy;

    @Size(max = 100, message = "updatedBy must not exceed 100 characters")
    private String updatedBy;

    @Size(max = 1000, message = "remarks must not exceed 1000 characters")
    private String remarks;
}
