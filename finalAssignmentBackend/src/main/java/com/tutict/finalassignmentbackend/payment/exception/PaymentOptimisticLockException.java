package com.tutict.finalassignmentbackend.payment.exception;

import com.tutict.finalassignmentbackend.exception.OptimisticLockException;

public class PaymentOptimisticLockException extends OptimisticLockException {

    public PaymentOptimisticLockException(String message) {
        super(message);
    }
}
