package com.tutict.finalassignmentbackend.ai.agent;

import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.dto.response.UserProfileResponse;
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
        return username == null ? "anonymous" : username;
    }

    public static AgentToolContext from(
            Authentication authentication,
            AiAgentRole role,
            String sessionKey,
            UserProfileResponse profile,
            boolean confirmed,
            String confirmDraftId
    ) {
        String username = authentication == null ? null : authentication.getName();
        Long authUserId = profile == null ? null : profile.getAuthUserId();
        Long driverId = profile == null ? null : profile.getDriverId();
        return new AgentToolContext(
                authentication,
                role == null ? AiAgentRole.DRIVER : role,
                sessionKey,
                username,
                authUserId,
                driverId,
                confirmed,
                confirmDraftId
        );
    }
}
