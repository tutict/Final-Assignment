package com.tutict.finalassignmentcloud.ai.agent;

import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRole;
import org.springframework.security.core.Authentication;

public record AgentToolContext(
        Authentication authentication,
        AiAgentRole role,
        String sessionKey,
        String username,
        Long authUserId,
        Long driverId,
        boolean confirmed,
        String confirmDraftId
) {
    public boolean isUser() {
        return role == AiAgentRole.DRIVER;
    }

    public boolean isAdmin() {
        return role == AiAgentRole.ADMIN || role == AiAgentRole.SUPER_ADMIN;
    }

    public boolean isSuperAdmin() {
        return role == AiAgentRole.SUPER_ADMIN;
    }

    public String userKey() {
        if (authUserId != null) {
            return String.valueOf(authUserId);
        }
        return username == null || username.isBlank() ? "anonymous" : username;
    }
}
