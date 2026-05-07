package com.tutict.finalassignmentbackend.rag.event;

import java.time.Instant;

public interface DomainEvent {

    String eventId();

    String aggregateId();

    Instant occurredAt();
}
