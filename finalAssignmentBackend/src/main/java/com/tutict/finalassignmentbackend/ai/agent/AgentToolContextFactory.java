package com.tutict.finalassignmentbackend.ai.agent;

import com.tutict.finalassignmentbackend.ai.chat.AiCallerIdentity;
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

    public AgentToolContext create(String sessionKey, Map<String, Object> metadata, AiCallerIdentity identity) {
        return create(sessionKey, metadata, false, null, identity);
    }

    public AgentToolContext create(String sessionKey, boolean confirmed, String confirmDraftId) {
        return create(sessionKey, Map.of(), confirmed, confirmDraftId);
    }

    public AgentToolContext create(String sessionKey, Map<String, Object> metadata, boolean confirmed, String confirmDraftId) {
        return create(sessionKey, metadata, confirmed, confirmDraftId, captureIdentity());
    }

    public AgentToolContext create(
            String sessionKey,
            Map<String, Object> metadata,
            boolean confirmed,
            String confirmDraftId,
            AiCallerIdentity identity
    ) {
        AiCallerIdentity snapshot = identity == null ? AiCallerIdentity.anonymous() : identity;
        Map<String, Object> requestMetadata = metadata == null ? Map.of() : metadata;
        AiAgentRole role = snapshot.isAuthenticated()
                ? roleResolver.resolve(snapshot.roles())
                : roleResolver.resolve(requestMetadata);
        if (snapshot.isAuthenticated()) {
            return new AgentToolContext(
                    snapshot.authentication(),
                    role,
                    sessionKey,
                    snapshot.username(),
                    snapshot.authUserId(),
                    snapshot.driverId(),
                    confirmed,
                    confirmDraftId
            );
        }
        Authentication authentication = snapshot.authentication();
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

    private AiCallerIdentity captureIdentity() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        UserProfileResponse profile = null;
        if (authentication != null && authentication.getName() != null && !authentication.getName().isBlank()) {
            try {
                profile = authWsService.getCurrentUserProfile(authentication.getName());
            } catch (RuntimeException ignored) {
                profile = null;
            }
        }
        return AiCallerIdentity.from(authentication, profile);
    }
}
