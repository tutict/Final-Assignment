package com.tutict.finalassignmentcloud.ai.chat;

import com.tutict.finalassignmentcloud.ai.client.UserProfileClient;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class AiCallerIdentityFactory {

    private final ObjectProvider<UserProfileClient> userProfileClient;

    public AiCallerIdentityFactory(ObjectProvider<UserProfileClient> userProfileClient) {
        this.userProfileClient = userProfileClient;
    }

    public AiCallerIdentity capture() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        Long authUserId = null;
        Long driverId = null;
        UserProfileClient client = userProfileClient.getIfAvailable();
        if (client != null && authentication != null && authentication.getName() != null) {
            try {
                Map<String, Object> profile = client.findByUsername(authentication.getName());
                if (profile != null) {
                    authUserId = asLong(profile.get("authUserId"), profile.get("userId"), profile.get("id"));
                    driverId = asLong(profile.get("driverId"));
                }
            } catch (RuntimeException ignored) {
                // Identity capture must not fail the stream.
            }
        }
        return AiCallerIdentity.from(authentication, authUserId, driverId);
    }

    private static Long asLong(Object... values) {
        for (Object value : values) {
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
