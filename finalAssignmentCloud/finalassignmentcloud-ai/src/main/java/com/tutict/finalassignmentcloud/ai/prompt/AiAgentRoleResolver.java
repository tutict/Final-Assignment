package com.tutict.finalassignmentcloud.ai.prompt;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.lang.reflect.Array;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Service
public class AiAgentRoleResolver {

    public AiAgentRole resolve(Map<String, Object> metadata) {
        Set<String> roles = roleCodes(metadata);
        if (roles.contains("SUPER_ADMIN")) {
            return AiAgentRole.SUPER_ADMIN;
        }
        if (roles.contains("ADMIN")) {
            return AiAgentRole.ADMIN;
        }
        return AiAgentRole.DRIVER;
    }

    public List<String> resolveRoleCodes(Map<String, Object> metadata) {
        return List.copyOf(roleCodes(metadata));
    }

    private Set<String> roleCodes(Map<String, Object> metadata) {
        Set<String> authenticated = authenticatedRoleCodes();
        if (!authenticated.isEmpty()) {
            return authenticated;
        }
        return metadataRoleCodes(metadata);
    }

    private Set<String> authenticatedRoleCodes() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return Set.of();
        }
        Set<String> roles = new LinkedHashSet<>();
        for (GrantedAuthority authority : authentication.getAuthorities()) {
            String normalized = normalize(authority.getAuthority());
            if (!normalized.isBlank()) {
                roles.add(normalized);
            }
        }
        return roles;
    }

    private Set<String> metadataRoleCodes(Map<String, Object> metadata) {
        if (metadata == null || metadata.isEmpty()) {
            return Set.of();
        }
        Set<String> roles = new LinkedHashSet<>();
        collectRoleValues(roles, metadata.get("roles"));
        collectRoleValues(roles, metadata.get("role"));
        collectRoleValues(roles, metadata.get("userRole"));
        collectRoleValues(roles, metadata.get("user_role"));
        return roles;
    }

    private void collectRoleValues(Set<String> roles, Object value) {
        if (value == null) {
            return;
        }
        if (value instanceof Collection<?> collection) {
            for (Object item : collection) {
                collectRoleValues(roles, item);
            }
            return;
        }
        if (value.getClass().isArray()) {
            int length = Array.getLength(value);
            for (int index = 0; index < length; index++) {
                collectRoleValues(roles, Array.get(value, index));
            }
            return;
        }
        for (String raw : value.toString().split(",")) {
            String normalized = normalize(raw);
            if (!normalized.isBlank()) {
                roles.add(normalized);
            }
        }
    }

    private static String normalize(String role) {
        if (role == null) {
            return "";
        }
        String normalized = role
                .replace("\"", "")
                .replace("'", "")
                .trim()
                .toUpperCase(Locale.ROOT);
        if (normalized.startsWith("ROLE_")) {
            normalized = normalized.substring("ROLE_".length());
        }
        if ("ROLE_ADMIN".equals(normalized)) {
            return "ADMIN";
        }
        if ("USER".equals(normalized) || "DRIVER".equals(normalized)) {
            return "USER";
        }
        return normalized;
    }
}
