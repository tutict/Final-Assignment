package finalassignmentbackend.config.login.jwt;

import finalassignmentbackend.enums.DataScope;
import finalassignmentbackend.enums.RoleType;
import io.smallrye.jwt.auth.principal.JWTParser;
import io.smallrye.jwt.auth.principal.ParseException;
import io.smallrye.jwt.build.Jwt;
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.jwt.JsonWebToken;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.util.Arrays;
import java.util.Base64;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.time.Duration;
import java.time.Instant;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@ApplicationScoped
public class TokenProvider {

    private static final Logger LOG = Logger.getLogger(TokenProvider.class.getName());

    @ConfigProperty(name = "jwt.secret.key")
    String base64Secret;

    @Inject
    JWTParser jwtParser;

    private SecretKey secretKey;

    private static final Map<String, RoleMetadata> ROLE_SCHEMA;

    static {
        Map<String, RoleMetadata> schema = new LinkedHashMap<>();
        schema.put("SUPER_ADMIN", new RoleMetadata(RoleType.SYSTEM, DataScope.ALL));
        schema.put("ADMIN", new RoleMetadata(RoleType.SYSTEM, DataScope.ALL));
        schema.put("TRAFFIC_POLICE", new RoleMetadata(RoleType.BUSINESS, DataScope.DEPARTMENT));
        schema.put("FINANCE", new RoleMetadata(RoleType.BUSINESS, DataScope.DEPARTMENT));
        schema.put("APPEAL_REVIEWER", new RoleMetadata(RoleType.BUSINESS, DataScope.DEPARTMENT));
        ROLE_SCHEMA = Collections.unmodifiableMap(schema);
    }

    @PostConstruct
    public void init() {
        byte[] keyBytes = Base64.getDecoder().decode(base64Secret);
        this.secretKey = new SecretKeySpec(keyBytes, "HmacSHA256");
        LOG.info("TokenProvider initialized with HS256 secret key");
    }

    public String createToken(String username, String roles) {
        if (!validateRoleCodes(roles)) {
            throw new IllegalArgumentException("Invalid role codes provided for token creation");
        }
        String normalizedRoles = String.join(",", normalizeRoleCodes(roles));
        Instant now = Instant.now();
        return Jwt.claims()
                .subject(username)
                .claim("roles", normalizedRoles)
                .issuedAt(now)
                .expiresAt(now.plus(Duration.ofDays(1)))
                .sign(secretKey);
    }

    public String createEnhancedToken(String username, String roleCodes, String roleTypes, String dataScope) {
        if (!validateRoleClaims(roleCodes, roleTypes, dataScope)) {
            throw new IllegalArgumentException("Role claims do not match the schema");
        }
        String normalizedRoles = String.join(",", normalizeRoleCodes(roleCodes));
        Instant now = Instant.now();
        return Jwt.claims()
                .subject(username)
                .claim("roles", normalizedRoles)
                .claim("roleTypes", roleTypes)
                .claim("dataScope", dataScope)
                .issuedAt(now)
                .expiresAt(now.plus(Duration.ofDays(1)))
                .sign(secretKey);
    }

    public boolean validateToken(String token) {
        try {
            jwtParser.verify(token, secretKey);
            LOG.log(Level.INFO, "Token validated successfully: {0}", token);
            return true;
        } catch (ParseException e) {
            LOG.log(Level.WARNING, "Invalid token: {0}", e.getMessage());
            return false;
        }
    }

    public List<String> extractRoles(String token) {
        try {
            JsonWebToken jwt = jwtParser.verify(token, secretKey);
            String roles = jwt.getClaim("roles");
            if (roles != null && !roles.isEmpty()) {
                return normalizeRoleCodes(roles).stream()
                        .filter(this::isRoleDefined)
                        .map(role -> "ROLE_" + role)
                        .collect(Collectors.toList());
            }
            return List.of();
        } catch (ParseException e) {
            LOG.log(Level.WARNING, "Failed to extract roles from token: {0}", e.getMessage());
            return List.of();
        }
    }

    public String getUsernameFromToken(String token) {
        try {
            return jwtParser.verify(token, secretKey).getSubject();
        } catch (ParseException e) {
            LOG.log(Level.WARNING, "Failed to extract subject from token: {0}", e.getMessage());
            return null;
        }
    }

    public List<RoleType> extractRoleTypes(String token) {
        try {
            JsonWebToken jwt = jwtParser.verify(token, secretKey);
            String roleTypes = jwt.getClaim("roleTypes");
            if (roleTypes != null && !roleTypes.isEmpty()) {
                return Arrays.stream(roleTypes.split(","))
                        .map(String::trim)
                        .map(RoleType::fromCode)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
            }
            return List.of();
        } catch (ParseException e) {
            LOG.log(Level.WARNING, "Failed to extract role types from token: {0}", e.getMessage());
            return List.of();
        }
    }

    public DataScope extractDataScope(String token) {
        try {
            JsonWebToken jwt = jwtParser.verify(token, secretKey);
            String dataScope = jwt.getClaim("dataScope");
            return DataScope.fromCode(dataScope);
        } catch (ParseException e) {
            LOG.log(Level.WARNING, "Failed to extract data scope from token: {0}", e.getMessage());
            return null;
        }
    }

    public boolean hasRoleType(String token, RoleType roleType) {
        return extractRoleTypes(token).contains(roleType);
    }

    public boolean hasSystemRole(String token) {
        return hasRoleType(token, RoleType.SYSTEM);
    }

    public boolean hasBusinessRole(String token) {
        return hasRoleType(token, RoleType.BUSINESS);
    }

    public boolean hasDataScopePermission(String token, DataScope requiredDataScope) {
        DataScope userScope = extractDataScope(token);
        if (userScope == null) {
            return false;
        }
        return userScope.includes(requiredDataScope);
    }

    public boolean validateRoleCodes(String roleCodes) {
        List<String> normalized = normalizeRoleCodes(roleCodes);
        if (normalized.isEmpty()) {
            return false;
        }
        boolean valid = normalized.stream().allMatch(this::isRoleDefined);
        if (!valid) {
            LOG.log(Level.WARNING, "Detected undefined role codes: {0}", normalized);
        }
        return valid;
    }

    public boolean validateRoleClaims(String roleCodes, String roleTypes, String dataScope) {
        if (!validateRoleCodes(roleCodes)) {
            return false;
        }
        if (!validateRoleTypes(roleTypes) || !validateDataScope(dataScope)) {
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

        for (String roleCode : normalizeRoleCodes(roleCodes)) {
            RoleMetadata metadata = ROLE_SCHEMA.get(roleCode);
            if (metadata == null) {
                LOG.log(Level.WARNING, "Role {0} not defined in schema", roleCode);
                return false;
            }
            if (!requestedTypes.contains(metadata.getRoleType())) {
                LOG.log(Level.WARNING,
                        "Role type {0} missing from claim for role {1}",
                        new Object[]{metadata.getRoleType().getCode(), roleCode});
                return false;
            }
            if (!requestedScope.includes(metadata.getDataScope())) {
                LOG.log(Level.WARNING,
                        "Data scope {0} does not cover required scope {1} for role {2}",
                        new Object[]{requestedScope.getCode(), metadata.getDataScope().getCode(), roleCode});
                return false;
            }
        }

        return true;
    }

    public boolean validateRoleTypes(String roleTypes) {
        if (roleTypes == null || roleTypes.trim().isEmpty()) {
            return false;
        }
        return Arrays.stream(roleTypes.split(","))
                .map(String::trim)
                .allMatch(RoleType::isValid);
    }

    public boolean validateDataScope(String dataScope) {
        return DataScope.isValid(dataScope);
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

    private boolean isRoleDefined(String roleCode) {
        return ROLE_SCHEMA.containsKey(roleCode);
    }

    private static final class RoleMetadata {
        private final RoleType roleType;
        private final DataScope dataScope;

        private RoleMetadata(RoleType roleType, DataScope dataScope) {
            this.roleType = roleType;
            this.dataScope = dataScope;
        }

        RoleType getRoleType() {
            return roleType;
        }

        DataScope getDataScope() {
            return dataScope;
        }
    }
}
