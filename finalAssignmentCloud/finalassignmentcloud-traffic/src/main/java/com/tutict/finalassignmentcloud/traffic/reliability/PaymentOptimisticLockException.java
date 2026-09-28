package com.tutict.finalassignmentcloud.traffic.reliability;

public class PaymentOptimisticLockException extends RuntimeException {

    public PaymentOptimisticLockException(String message) {
        super(message);
    }
}