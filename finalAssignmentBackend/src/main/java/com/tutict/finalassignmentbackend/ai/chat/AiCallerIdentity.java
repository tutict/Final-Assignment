package com.tutict.finalassignmentbackend.ai.chat;

import com.tutict.finalassignmentbackend.config.security.SecurityRoleUtils;
import com.tutict.finalassignmentbackend.dto.response.UserProfileResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;

import java.util.List;

/**
 * Snapshot of the authenticated caller, captured on the request thread
 * before WebClient/reactor hops drop SecurityContext ThreadLocal state.
 */
public record AiCallerIdentity(
        Authentication authentication,
        String username,
        String userId,
        List<String> roles,
        String department,
        Long authUserId,
        Long driverId
) {
    public AiCallerIdentity {
        roles = roles == null ? List.of() : List.copyOf(roles);
    }

    public static AiCallerIdentity anonymous() {
        return new AiCallerIdentity(null, null, null, List.of(), null, null, null);
    }

    public static AiCallerIdentity from(Authentication authentication, UserProfileResponse profile) {
        if (authentication == null
                || !authentication.isAuthenticated()
                || "anonymousUser".equals(authentication.getPrincipal())) {
            return anonymous();
        }
        String username = authentication.getName();
        List<String> roles = authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .map(SecurityRoleUtils::normalizeRoleCode)
                .filter(role -> !role.isBlank())
                .toList();
        String department = null;
        for (String role : roles) {
            if ("SUPER_ADMIN".equals(role) || "ADMIN".equals(role)) {
                department = "ALL";
                break;
            }
            if ("TRAFFIC_POLICE".equals(role) || "FINANCE".equals(role) || "APPEAL_REVIEWER".equals(role)) {
                department = "DEPARTMENT";
                break;
            }
        }
        Long authUserId = profile == null ? null : profile.getAuthUserId();
        Long driverId = profile == null ? null : profile.getDriverId();
        return new AiCallerIdentity(
                authentication,
                username,
                username,
                roles,
                department,
                authUserId,
                driverId
        );
    }

    public boolean isAuthenticated() {
        return authentication != null && userId != null && !userId.isBlank();
    }

    public String userKey() {
        if (authUserId != null) {
            return String.valueOf(authUserId);
        }
        if (username != null && !username.isBlank()) {
            return username;
        }
        return "anonymous";
    }
}
