package com.tutict.finalassignmentbackend.config.login.jwt;

import com.tutict.finalassignmentbackend.enums.DataScope;
import com.tutict.finalassignmentbackend.enums.RoleType;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtBuilder;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.JwtParserBuilder;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Arrays;
import java.util.Base64;
import java.util.Collections;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Service
public class TokenProvider {

    private static final Logger LOG = Logger.getLogger(TokenProvider.class.getName());
    private static final String FORBIDDEN_DEFAULT_SECRET = "CHANGE_ME_IN_PRODUCTION";
    private static final int MIN_HS256_SECRET_BYTES = 32;

    @Value("${jwt.secret:}")
    private String secret;

    @Value("${jwt.algorithm:HS256}")
    private String configuredAlgorithm;

    @Value("${jwt.private-key:}")
    private String privateKeyPem;

    @Value("${jwt.public-key:}")
    private String publicKeyPem;

    @Value("${jwt.access-token-expiration:3600}")
    private long accessTokenExpirationSeconds;

    private JwtAlgorithm algorithm;
    private SecretKey secretKey;
    private PrivateKey privateKey;
    private PublicKey publicKey;

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
        if (accessTokenExpirationSeconds <= 0) {
            throw new IllegalStateException("jwt.access-token-expiration must be greater than 0 seconds");
        }
        this.algorithm = JwtAlgorithm.from(configuredAlgorithm);
        if (algorithm == JwtAlgorithm.RS256) {
            initRsaKeys();
        } else {
            initHmacSecret();
        }
        LOG.info(() -> String.format("TokenProvider initialized with %s, access token ttl=%ss",
                algorithm, accessTokenExpirationSeconds));
    }

    public String createToken(String username, String roles) {
        if (!validateRoleCodes(roles)) {
            throw new IllegalArgumentException("Invalid role codes provided for token creation");
        }
        return buildAccessToken(username, String.join(",", normalizeRoleCodes(roles)), null, null);
    }

    public String createEnhancedToken(String username, String roleCodes, String roleTypes, String dataScope) {
        if (!validateRoleClaims(roleCodes, roleTypes, dataScope)) {
            throw new IllegalArgumentException("Role claims do not match the database schema");
        }
        return buildAccessToken(username, String.join(",", normalizeRoleCodes(roleCodes)), roleTypes, dataScope);
    }

    public long getExpirationMs(String token) {
        Date expiration = parseClaims(token).getExpiration();
        if (expiration == null) {
            return 0L;
        }
        return Math.max(expiration.getTime() - System.currentTimeMillis(), 0L);
    }

    public long getAccessTokenExpirationSeconds() {
        return accessTokenExpirationSeconds;
    }

    public boolean validateToken(String token) {
        try {
            parseClaims(token);
            LOG.log(Level.FINE, "Token validated successfully");
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            LOG.log(Level.WARNING, "Invalid token: " + e.getMessage(), e);
            return false;
        }
    }

    public List<String> extractRoles(String token) {
        try {
            String roles = parseClaims(token).get("roles", String.class);
            if (roles != null && !roles.isEmpty()) {
                return normalizeRoleCodes(roles).stream()
                        .filter(this::isRoleDefined)
                        .map(role -> "ROLE_" + role)
                        .collect(Collectors.toList());
            }
            return List.of();
        } catch (JwtException | IllegalArgumentException e) {
            LOG.log(Level.WARNING, "Failed to extract roles from token: " + e.getMessage(), e);
            return List.of();
        }
    }

    public String getUsernameFromToken(String token) {
        return parseClaims(token).getSubject();
    }

    public List<RoleType> extractRoleTypes(String token) {
        try {
            String roleTypes = parseClaims(token).get("roleTypes", String.class);
            if (roleTypes != null && !roleTypes.isEmpty()) {
                return Arrays.stream(roleTypes.split(","))
                        .map(String::trim)
                        .map(RoleType::fromCode)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
            }
            return List.of();
        } catch (JwtException | IllegalArgumentException e) {
            LOG.log(Level.WARNING, "Failed to extract role types from token: " + e.getMessage(), e);
            return List.of();
        }
    }

    public DataScope extractDataScope(String token) {
        try {
            String dataScope = parseClaims(token).get("dataScope", String.class);
            return DataScope.fromCode(dataScope);
        } catch (JwtException | IllegalArgumentException e) {
            LOG.log(Level.WARNING, "Failed to extract data scope from token: " + e.getMessage(), e);
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
        DataScope userDataScope = extractDataScope(token);
        return userDataScope != null && userDataScope.includes(requiredDataScope);
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

    private String buildAccessToken(String username, String roles, String roleTypes, String dataScope) {
        long now = System.currentTimeMillis();
        Date issuedAt = new Date(now);
        Date expirationDate = new Date(now + accessTokenExpirationSeconds * 1000L);

        JwtBuilder builder = Jwts.builder()
                .subject(username)
                .claim("roles", roles)
                .issuedAt(issuedAt)
                .expiration(expirationDate);

        if (roleTypes != null) {
            builder.claim("roleTypes", roleTypes);
        }
        if (dataScope != null) {
            builder.claim("dataScope", dataScope);
        }

        return sign(builder).compact();
    }

    private JwtBuilder sign(JwtBuilder builder) {
        if (algorithm == JwtAlgorithm.RS256) {
            return builder.signWith(privateKey, Jwts.SIG.RS256);
        }
        return builder.signWith(secretKey);
    }

    private Claims parseClaims(String token) {
        JwtParserBuilder parser = Jwts.parser();
        if (algorithm == JwtAlgorithm.RS256) {
            parser.verifyWith(publicKey);
        } else {
            parser.verifyWith(secretKey);
        }
        return parser.build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private void initHmacSecret() {
        if (secret == null || secret.isBlank() || FORBIDDEN_DEFAULT_SECRET.equals(secret)) {
            throw new IllegalStateException("jwt.secret must be provided through JWT_SECRET and cannot use CHANGE_ME_IN_PRODUCTION");
        }
        byte[] keyBytes = secret.getBytes(StandardCharsets.UTF_8);
        if (keyBytes.length < MIN_HS256_SECRET_BYTES) {
            throw new IllegalStateException("jwt.secret must be at least 32 bytes for HS256");
        }
        this.secretKey = Keys.hmacShaKeyFor(keyBytes);
    }

    private void initRsaKeys() {
        try {
            this.privateKey = loadPrivateKey(privateKeyPem);
            this.publicKey = loadPublicKey(publicKeyPem);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to initialize RS256 keys", ex);
        }
    }

    private PrivateKey loadPrivateKey(String pem) throws Exception {
        byte[] encoded = decodePem(pem, "PRIVATE KEY");
        return KeyFactory.getInstance("RSA").generatePrivate(new PKCS8EncodedKeySpec(encoded));
    }

    private PublicKey loadPublicKey(String pem) throws Exception {
        byte[] encoded = decodePem(pem, "PUBLIC KEY");
        return KeyFactory.getInstance("RSA").generatePublic(new X509EncodedKeySpec(encoded));
    }

    private byte[] decodePem(String pem, String type) {
        if (pem == null || pem.isBlank()) {
            throw new IllegalStateException("jwt." + type.toLowerCase(Locale.ROOT).replace(' ', '-') + " must be configured for RS256");
        }
        String normalized = pem.replace("\\n", "\n").replace("\r", "").trim();
        if (normalized.contains("BEGIN RSA PRIVATE KEY")) {
            throw new IllegalStateException("RS256 private key must be PKCS#8 PEM. Convert it with: openssl pkcs8 -topk8 -nocrypt -in private.pem -out private_pkcs8.pem");
        }
        String base64 = normalized
                .replace("-----BEGIN " + type + "-----", "")
                .replace("-----END " + type + "-----", "")
                .replaceAll("\\s", "");
        return Base64.getDecoder().decode(base64);
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

    private enum JwtAlgorithm {
        HS256,
        RS256;

        static JwtAlgorithm from(String value) {
            if (value == null || value.isBlank()) {
                return HS256;
            }
            return JwtAlgorithm.valueOf(value.trim().toUpperCase(Locale.ROOT));
        }
    }

    @Getter
    private static final class RoleMetadata {
        private final RoleType roleType;
        private final DataScope dataScope;

        private RoleMetadata(RoleType roleType, DataScope dataScope) {
            this.roleType = roleType;
            this.dataScope = dataScope;
        }
    }
}
