package com.tutict.finalassignmentbackend.payment.exception;

public class PaymentDuplicateRequestException extends RuntimeException {

    public PaymentDuplicateRequestException(String message) {
        super(message);
    }

    public PaymentDuplicateRequestException(String message, Throwable cause) {
        super(message, cause);
    }
}
