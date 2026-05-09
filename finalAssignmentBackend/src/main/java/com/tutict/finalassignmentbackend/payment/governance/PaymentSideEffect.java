package com.tutict.finalassignmentbackend.payment.governance;

public enum PaymentSideEffect {
    DB_MUTATION,
    KAFKA_PUBLISH,
    ES_INDEX,
    CACHE_EVICT,
    WORKFLOW_TRANSITION,
    PAYMENT_COMPLETION,
    READ_REPAIR,
    NONE
}
