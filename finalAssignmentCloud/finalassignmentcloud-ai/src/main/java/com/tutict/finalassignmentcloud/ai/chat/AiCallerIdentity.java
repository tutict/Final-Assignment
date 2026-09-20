package com.tutict.finalassignmentcloud.ai.chat;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;

import java.util.List;

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

    public static AiCallerIdentity from(Authentication authentication, Long authUserId, Long driverId) {
        if (authentication == null
                || !authentication.isAuthenticated()
                || "anonymousUser".equals(authentication.getPrincipal())) {
            return anonymous();
        }
        String username = authentication.getName();
        List<String> roles = authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .map(AiCallerIdentity::normalizeRole)
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

    private static String normalizeRole(String role) {
        if (role == null) {
            return "";
        }
        String normalized = role.trim().toUpperCase();
        if (normalized.startsWith("ROLE_")) {
            normalized = normalized.substring("ROLE_".length());
        }
        if ("USER".equals(normalized) || "DRIVER".equals(normalized)) {
            return "USER";
        }
        return normalized;
    }
}
