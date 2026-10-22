package com.tutict.finalassignmentcloud.config.security;

import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;

import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

public final class SecurityRoleUtils {

    private SecurityRoleUtils() {
    }

    /**
     * 判断请求是否由真实登录主体发起。
     *
     * <p>Spring Security 的匿名过滤器会为未认证请求放入 {@link AnonymousAuthenticationToken}，
     * 因此仅判断 {@code authentication != null} 会把匿名请求误判为已认证。
     */
    public static boolean isAuthenticated(Authentication authentication) {
        return authentication != null
                && authentication.isAuthenticated()
                && !(authentication instanceof AnonymousAuthenticationToken);
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
                .collect(Collectors.toSet());

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
