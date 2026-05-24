package com.tutict.finalassignmentbackend.config.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;

import java.util.Locale;
import java.util.Set;

public final class SecurityRoleUtils {

    private SecurityRoleUtils() {
    }

    public static boolean hasRole(Authentication authentication, String role) {
        return hasAnyRole(authentication, Set.of(role));
    }

    public static boolean hasAnyRole(Authentication authentication, Set<String> roles) {
        if (authentication == null || roles == null || roles.isEmpty()) {
            return false;
        }
        Set<String> normalizedRoles = roles.stream()
                .map(SecurityRoleUtils::normalizeRoleCode)
                .filter(role -> !role.isBlank())
                .collect(java.util.stream.Collectors.toSet());

        return authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .map(SecurityRoleUtils::normalizeRoleCode)
                .anyMatch(normalizedRoles::contains);
    }

    public static String normalizeRoleCode(String role) {
        if (role == null) {
            return "";
        }
        String normalized = role.trim().toUpperCase(Locale.ROOT);
        if (normalized.startsWith("ROLE_")) {
            return normalized.substring("ROLE_".length());
        }
        return normalized;
    }
}
