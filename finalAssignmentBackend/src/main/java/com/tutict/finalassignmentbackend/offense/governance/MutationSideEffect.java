package com.tutict.finalassignmentbackend.offense.governance;

public enum MutationSideEffect {
    DB_MUTATION,
    KAFKA_PUBLISH,
    ES_INDEX,
    CACHE_EVICT,
    READ_REPAIR,
    NONE
}
