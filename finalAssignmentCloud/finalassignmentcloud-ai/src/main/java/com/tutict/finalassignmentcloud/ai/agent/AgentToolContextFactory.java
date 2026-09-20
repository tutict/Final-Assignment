package com.tutict.finalassignmentcloud.ai.agent;

import com.tutict.finalassignmentcloud.ai.chat.AiCallerIdentity;
import com.tutict.finalassignmentcloud.ai.client.UserProfileClient;
import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRoleResolver;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class AgentToolContextFactory {

    private final AiAgentRoleResolver roleResolver;
    private final ObjectProvider<UserProfileClient> userProfileClient;

    public AgentToolContextFactory(
            AiAgentRoleResolver roleResolver,
            ObjectProvider<UserProfileClient> userProfileClient
    ) {
        this.roleResolver = roleResolver;
        this.userProfileClient = userProfileClient;
    }

    public AgentToolContext create(String sessionKey, Map<String, Object> metadata) {
        return create(sessionKey, metadata, captureIdentity(metadata));
    }

    public AgentToolContext create(String sessionKey, Map<String, Object> metadata, AiCallerIdentity identity) {
        AiCallerIdentity snapshot = identity == null ? AiCallerIdentity.anonymous() : identity;
        Map<String, Object> requestMetadata = metadata == null ? Map.of() : metadata;
        AiAgentRole role = snapshot.isAuthenticated()
                ? roleResolver.resolve(Map.of("roles", snapshot.roles()))
                : roleResolver.resolve(requestMetadata);
        return new AgentToolContext(
                snapshot.authentication(),
                role,
                sessionKey,
                snapshot.username(),
                snapshot.authUserId(),
                snapshot.driverId(),
                false,
                null
        );
    }

    private AiCallerIdentity captureIdentity(Map<String, Object> metadata) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        Long authUserId = longValue(metadata, "authUserId", "userId");
        Long driverId = longValue(metadata, "driverId");
        if ((authUserId == null || driverId == null) && authentication != null && authentication.getName() != null) {
            UserProfileClient client = userProfileClient.getIfAvailable();
            if (client != null) {
                try {
                    Map<String, Object> profile = client.findByUsername(authentication.getName());
                    if (profile != null) {
                        if (authUserId == null) {
                            authUserId = longValue(profile, "authUserId", "userId", "id");
                        }
                        if (driverId == null) {
                            driverId = longValue(profile, "driverId");
                        }
                    }
                } catch (RuntimeException ignored) {
                    // Feign failure is converted to a missing profile, never a raw 500.
                }
            }
        }
        return AiCallerIdentity.from(authentication, authUserId, driverId);
    }

    private static Long longValue(Map<String, ?> source, String... keys) {
        if (source == null) {
            return null;
        }
        for (String key : keys) {
            Object value = source.get(key);
            if (value instanceof Number number) {
                return number.longValue();
            }
            if (value != null && !value.toString().isBlank()) {
                try {
                    return Long.parseLong(value.toString());
                } catch (NumberFormatException ignored) {
                    return null;
                }
            }
        }
        return null;
    }
}
