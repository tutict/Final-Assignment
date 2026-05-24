package com.tutict.finalassignmentbackend.dto.mapper;

import com.tutict.finalassignmentbackend.dto.response.PaymentRecordResponse;
import com.tutict.finalassignmentbackend.entity.payment.PaymentRecord;

public final class PaymentRecordResponseMapper {

    private PaymentRecordResponseMapper() {
    }

    public static PaymentRecordResponse toResponse(PaymentRecord record) {
        if (record == null) {
            return null;
        }
        return PaymentRecordResponse.builder()
                .paymentId(record.getPaymentId())
                .fineId(record.getFineId())
                .driverId(record.getDriverId())
                .paymentNumber(record.getPaymentNumber())
                .paymentAmount(record.getPaymentAmount())
                .paymentMethod(record.getPaymentMethod())
                .paymentTime(record.getPaymentTime())
                .paymentChannel(record.getPaymentChannel())
                .payerName(record.getPayerName())
                .payerIdCard(maskIdCard(record.getPayerIdCard()))
                .payerContact(maskPhone(record.getPayerContact()))
                .bankName(record.getBankName())
                .bankAccount(maskBankAccount(record.getBankAccount()))
                .transactionId(record.getTransactionId())
                .receiptNumber(record.getReceiptNumber())
                .receiptUrl(record.getReceiptUrl())
                .paymentStatus(record.getPaymentStatus())
                .refundAmount(record.getRefundAmount())
                .refundTime(record.getRefundTime())
                .createdAt(record.getCreatedAt())
                .updatedAt(record.getUpdatedAt())
                .remarks(record.getRemarks())
                .build();
    }

    private static String maskPhone(String phone) {
        if (phone == null || phone.length() < 11) {
            return phone;
        }
        return phone.substring(0, 3) + "****" + phone.substring(7);
    }

    private static String maskIdCard(String idCard) {
        if (idCard == null || idCard.length() < 10) {
            return idCard;
        }
        return idCard.substring(0, 6) + "********" + idCard.substring(idCard.length() - 4);
    }

    private static String maskBankAccount(String bankAccount) {
        if (bankAccount == null || bankAccount.length() < 8) {
            return bankAccount;
        }
        return "**** **** **** " + bankAccount.substring(bankAccount.length() - 4);
    }
}
