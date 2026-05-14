package com.tutict.finalassignmentbackend.payment.exception;

public class PaymentOptimisticLockException extends RuntimeException {

    public PaymentOptimisticLockException(String message) {
        super(message);
    }
}
