package com.tutict.finalassignmentcloud.config.security;

import com.tutict.finalassignmentcloud.enums.DataScope;
import com.tutict.finalassignmentcloud.enums.RoleType;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

import javax.crypto.SecretKey;
import java.util.Arrays;
import java.util.Base64;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

public class ServiceTokenProvider {

    private static final Logger LOG = Logger.getLogger(ServiceTokenProvider.class.getName());
    private static final Map<String, RoleMetadata> ROLE_SCHEMA;

    static {
        Map<String, RoleMetadata> schema = new LinkedHashMap<>();
        schema.put("SUPER_ADMIN", new RoleMetadata(RoleType.SYSTEM, DataScope.ALL));
        schema.put("ADMIN", new RoleMetadata(RoleType.SYSTEM, DataScope.ALL));
        schema.put("TRAFFIC_POLICE", new RoleMetadata(RoleType.BUSINESS, DataScope.DEPARTMENT));
        schema.put("FINANCE", new RoleMetadata(RoleType.BUSINESS, DataScope.DEPARTMENT));
        schema.put("APPEAL_REVIEWER", new RoleMetadata(RoleType.BUSINESS, DataScope.DEPARTMENT));
        schema.put("USER", new RoleMetadata(RoleType.CUSTOM, DataScope.SELF));
        ROLE_SCHEMA = Collections.unmodifiableMap(schema);
    }

    private final SecretKey secretKey;

    public ServiceTokenProvider(String base64Secret) {
        if (base64Secret == null || base64Secret.isBlank()) {
            throw new IllegalStateException("jwt.secret.key must be provided through configuration or JWT_SECRET_KEY");
        }
        byte[] keyBytes = Base64.getDecoder().decode(base64Secret);
        this.secretKey = Keys.hmacShaKeyFor(keyBytes);
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException ex) {
            LOG.log(Level.WARNING, "Invalid JWT: {0}", ex.getMessage());
            return false;
        }
    }

    public String getUsernameFromToken(String token) {
        return parseClaims(token).getSubject();
    }

    public List<String> extractRoles(String token) {
        try {
            String roles = parseClaims(token).get("roles", String.class);
            return normalizeRoleCodes(roles).stream()
                    .filter(ROLE_SCHEMA::containsKey)
                    .map(role -> "ROLE_" + role)
                    .collect(Collectors.toList());
        } catch (JwtException | IllegalArgumentException ex) {
            LOG.log(Level.WARNING, "Failed to extract roles from JWT: {0}", ex.getMessage());
            return List.of();
        }
    }

    public boolean validateRoleClaims(String roleCodes, String roleTypes, String dataScope) {
        List<String> normalizedRoles = normalizeRoleCodes(roleCodes);
        if (normalizedRoles.isEmpty() || normalizedRoles.stream().anyMatch(role -> !ROLE_SCHEMA.containsKey(role))) {
            return false;
        }
        if (roleTypes == null || roleTypes.isBlank() || dataScope == null || dataScope.isBlank()) {
            return false;
        }
        DataScope requestedScope = DataScope.fromCode(dataScope);
        if (requestedScope == null) {
            return false;
        }
        Set<RoleType> requestedTypes = Arrays.stream(roleTypes.split(","))
                .map(String::trim)
                .map(RoleType::fromCode)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        return normalizedRoles.stream()
                .map(ROLE_SCHEMA::get)
                .allMatch(metadata -> requestedTypes.contains(metadata.roleType())
                        && requestedScope.includes(metadata.dataScope()));
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private List<String> normalizeRoleCodes(String roleCodes) {
        if (roleCodes == null) {
            return List.of();
        }
        return Arrays.stream(roleCodes.split(","))
                .map(code -> code.trim().toUpperCase(Locale.ROOT))
                .filter(code -> !code.isEmpty())
                .collect(Collectors.toList());
    }

    private record RoleMetadata(RoleType roleType, DataScope dataScope) {
    }
}
