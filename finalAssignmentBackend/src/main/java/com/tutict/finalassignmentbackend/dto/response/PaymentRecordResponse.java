package com.tutict.finalassignmentbackend.dto.response;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class PaymentRecordResponse {

    private Long paymentId;
    private Long fineId;
    private Long driverId;
    private String paymentNumber;
    private BigDecimal paymentAmount;
    private String paymentMethod;
    private LocalDateTime paymentTime;
    private String paymentChannel;
    private String payerName;
    private String payerIdCard;
    private String payerContact;
    private String bankName;
    private String bankAccount;
    private String transactionId;
    private String receiptNumber;
    private String receiptUrl;
    private String paymentStatus;
    private BigDecimal refundAmount;
    private LocalDateTime refundTime;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String remarks;
}
