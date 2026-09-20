package com.tutict.finalassignmentbackend.ai.agent;

import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRoleResolver;
import com.tutict.finalassignmentbackend.dto.response.UserProfileResponse;
import com.tutict.finalassignmentbackend.service.auth.AuthWsService;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class AgentToolContextFactory {

    private final AuthWsService authWsService;
    private final AiAgentRoleResolver roleResolver;

    public AgentToolContextFactory(AuthWsService authWsService, AiAgentRoleResolver roleResolver) {
        this.authWsService = authWsService;
        this.roleResolver = roleResolver;
    }

    public AgentToolContext create(String sessionKey) {
        return create(sessionKey, Map.of(), false, null);
    }

    public AgentToolContext create(String sessionKey, Map<String, Object> metadata) {
        return create(sessionKey, metadata, false, null);
    }

    public AgentToolContext create(String sessionKey, boolean confirmed, String confirmDraftId) {
        return create(sessionKey, Map.of(), confirmed, confirmDraftId);
    }

    public AgentToolContext create(String sessionKey, Map<String, Object> metadata, boolean confirmed, String confirmDraftId) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        AiAgentRole role = roleResolver.resolve(metadata == null ? Map.of() : metadata);
        UserProfileResponse profile = null;
        if (authentication != null && authentication.getName() != null && !authentication.getName().isBlank()) {
            try {
                profile = authWsService.getCurrentUserProfile(authentication.getName());
            } catch (RuntimeException ignored) {
                profile = null;
            }
        }
        return AgentToolContext.from(authentication, role, sessionKey, profile, confirmed, confirmDraftId);
    }
}
