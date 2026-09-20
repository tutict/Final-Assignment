package com.tutict.finalassignmentcloud.ai.agent;

import java.time.Instant;
import java.util.Map;

public record AgentDraft(
        String draftId,
        String userId,
        String sessionKey,
        String toolName,
        String serviceName,
        String risk,
        String summary,
        Map<String, Object> preview,
        Map<String, Object> payload,
        Instant createdAt,
        Instant expiresAt
) {
}
