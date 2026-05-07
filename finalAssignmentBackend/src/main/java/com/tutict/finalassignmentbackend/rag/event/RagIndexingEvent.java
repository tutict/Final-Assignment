package com.tutict.finalassignmentbackend.rag.event;

import java.time.Instant;
import java.util.Map;

public record RagIndexingEvent(
        String eventId,
        String aggregateId,
        String sourceTable,
        String sourceId,
        String status,
        Map<String, Object> metadata,
        Instant occurredAt
) implements DomainEvent {
}
