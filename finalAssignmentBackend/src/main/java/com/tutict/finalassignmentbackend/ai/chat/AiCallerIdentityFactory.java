package com.tutict.finalassignmentbackend.ai.chat;

import com.tutict.finalassignmentbackend.dto.response.UserProfileResponse;
import com.tutict.finalassignmentbackend.service.auth.AuthWsService;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class AiCallerIdentityFactory {

    private final AuthWsService authWsService;

    public AiCallerIdentityFactory(AuthWsService authWsService) {
        this.authWsService = authWsService;
    }

    public AiCallerIdentity capture() {
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
