package com.tutict.finalassignmentbackend.dto.mapper;

import com.tutict.finalassignmentbackend.dto.request.PaymentRecordRequest;
import com.tutict.finalassignmentbackend.entity.payment.PaymentRecord;

public final class PaymentRecordRequestMapper {

    private PaymentRecordRequestMapper() {
    }

    public static PaymentRecord toEntity(PaymentRecordRequest request) {
        if (request == null) {
            return null;
        }
        PaymentRecord record = new PaymentRecord();
        record.setFineId(request.getFineId());
        record.setDriverId(request.getDriverId());
        record.setPaymentNumber(request.getPaymentNumber());
        record.setPaymentAmount(request.getPaymentAmount());
        record.setPaymentMethod(request.getPaymentMethod());
        record.setPaymentTime(request.getPaymentTime());
        record.setPaymentChannel(request.getPaymentChannel());
        record.setPayerName(request.getPayerName());
        record.setPayerIdCard(request.getPayerIdCard());
        record.setPayerContact(request.getPayerContact());
        record.setBankName(request.getBankName());
        record.setBankAccount(request.getBankAccount());
        record.setTransactionId(request.getTransactionId());
        record.setReceiptNumber(request.getReceiptNumber());
        record.setReceiptUrl(request.getReceiptUrl());
        record.setPaymentStatus(request.getPaymentStatus());
        record.setVersion(request.getVersion());
        record.setRefundAmount(request.getRefundAmount());
        record.setRefundTime(request.getRefundTime());
        record.setCreatedBy(request.getCreatedBy());
        record.setUpdatedBy(request.getUpdatedBy());
        record.setRemarks(request.getRemarks());
        return record;
    }
}
