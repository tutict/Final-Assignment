package com.tutict.finalassignmentbackend.payment.messaging;

import com.tutict.finalassignmentbackend.entity.PaymentRecord;

public record PaymentRecordKafkaEvent(
        String topic,
        String idempotencyKey,
        PaymentRecord paymentRecord
) {
}
