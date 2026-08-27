package finalassignmentbackend.config.login.jwt;

import finalassignmentbackend.config.security.pqc.MlDsaKeyRing;
import finalassignmentbackend.config.security.pqc.PqcProviderInitializer;
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
import java.nio.charset.StandardCharsets;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.Signature;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * JWT 签发 / 校验。对齐 Spring config/login/jwt/TokenProvider。
 *
 * <p>支持算法切换（{@code jwt.algorithm}）：HS256（默认，SmallRye JWT）/ ML-DSA-65（FIPS 204，手写签名，
 * 因为 jjwt / SmallRye 均不支持 ML-DSA）。ML-DSA 模式下用 {@link MlDsaKeyRing} 版本化密钥环签名并写 kid，
 * 校验按 kid 选公钥、无 kid 回退到活跃公钥。
 */
@ApplicationScoped
public class TokenProvider {

    private static final Logger LOG = Logger.getLogger(TokenProvider.class.getName());
    private static final String FORBIDDEN_DEFAULT_SECRET = "CHANGE_ME_IN_PRODUCTION";
    private static final int MIN_HS256_SECRET_BYTES = 32;
    private static final String BC = org.bouncycastle.jce.provider.BouncyCastleProvider.PROVIDER_NAME;
    private static final String ML_DSA_ALGORITHM = "ML-DSA-65";   // BC KeyPairGenerator / Signature
    private static final String ML_DSA_JWT_ALG = "ML-DSA-65";     // JWT header alg

    @ConfigProperty(name = "jwt.secret.key", defaultValue = "")
    String base64Secret;

    @ConfigProperty(name = "jwt.algorithm", defaultValue = "HS256")
    String configuredAlgorithm;

    @ConfigProperty(name = "jwt.access-token-expiration", defaultValue = "86400")
    long accessTokenExpirationSeconds;

    @Inject
    JWTParser jwtParser;

    @Inject
    MlDsaKeyRing mlDsaKeyRing;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private JwtAlgorithm algorithm;
    private SecretKey secretKey;

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

    @PostConstruct
    public void init() {
        if (accessTokenExpirationSeconds <= 0) {
            throw new IllegalStateException("jwt.access-token-expiration must be greater than 0 seconds");
        }
        this.algorithm = JwtAlgorithm.from(configuredAlgorithm);
        if (algorithm == JwtAlgorithm.HS256) {
            initHmacSecret();
        } else if (algorithm == JwtAlgorithm.ML_DSA_65) {
            if (mlDsaKeyRing.activePrivateKey() == null) {
                throw new IllegalStateException("ML-DSA key ring has no active signing key; "
                        + "configure jwt.ml-dsa.keys or jwt.ml-dsa.private-key/public-key");
            }
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
            throw new IllegalArgumentException("Role claims do not match the schema");
        }
        return buildAccessToken(username, String.join(",", normalizeRoleCodes(roleCodes)), roleTypes, dataScope);
    }

    public boolean validateToken(String token) {
        try {
            claims(token);
            LOG.log(Level.FINE, "Token validated successfully");
            return true;
        } catch (RuntimeException | ParseException e) {
            LOG.log(Level.WARNING, "Invalid token: {0}", e.getMessage());
            return false;
        }
    }

    public List<String> extractRoles(String token) {
        try {
            Map<String, Object> c = claims(token);
            String roles = claimStr(c, "roles");
            if (roles != null && !roles.isEmpty()) {
                return normalizeRoleCodes(roles).stream()
                        .filter(this::isRoleDefined)
                        .map(role -> "ROLE_" + role)
                        .collect(Collectors.toList());
            }
            return List.of();
        } catch (RuntimeException | ParseException e) {
            LOG.log(Level.WARNING, "Failed to extract roles from token: {0}", e.getMessage());
            return List.of();
        }
    }

    public String getUsernameFromToken(String token) {
        try {
            return claimStr(claims(token), "sub");
        } catch (RuntimeException | ParseException e) {
            LOG.log(Level.WARNING, "Failed to extract subject from token: {0}", e.getMessage());
            return null;
        }
    }

    public List<RoleType> extractRoleTypes(String token) {
        try {
            String roleTypes = claimStr(claims(token), "roleTypes");
            if (roleTypes != null && !roleTypes.isEmpty()) {
                return Arrays.stream(roleTypes.split(","))
                        .map(String::trim)
                        .map(RoleType::fromCode)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
            }
            return List.of();
        } catch (RuntimeException | ParseException e) {
            LOG.log(Level.WARNING, "Failed to extract role types from token: {0}", e.getMessage());
            return List.of();
        }
    }

    public DataScope extractDataScope(String token) {
        try {
            String dataScope = claimStr(claims(token), "dataScope");
            return DataScope.fromCode(dataScope);
        } catch (RuntimeException | ParseException e) {
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
        return userScope != null && userScope.includes(requiredDataScope);
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

    /**
     * access token 的有效期（秒），供登录/刷新响应返回 expiresIn。
     */
    public long getAccessTokenExpirationSeconds() {
        return accessTokenExpirationSeconds;
    }

    /**
     * 返回该 token 距离过期的剩余毫秒数；无法解析或已过期时返回 0。
     * 用于登出时把 access token 加入黑名单，TTL 与其剩余寿命一致。
     */
    public long getExpirationMs(String token) {
        try {
            Map<String, Object> c = claims(token);
            long expMs = claimExpMs(c);
            return Math.max(expMs - System.currentTimeMillis(), 0L);
        } catch (RuntimeException | ParseException e) {
            LOG.log(Level.WARNING, "Failed to read expiration from token: {0}", e.getMessage());
            return 0L;
        }
    }

    // ---- token build / parse ----

    private String buildAccessToken(String username, String roles, String roleTypes, String dataScope) {
        long now = System.currentTimeMillis();
        if (algorithm == JwtAlgorithm.ML_DSA_65) {
            return buildMlDsaAccessToken(username, roles, roleTypes, dataScope, now);
        }
        Instant nowInstant = Instant.ofEpochMilli(now);
        Instant expInstant = nowInstant.plusSeconds(accessTokenExpirationSeconds);
        var builder = Jwt.claims()
                .subject(username)
                .claim("jti", UUID.randomUUID().toString())
                .claim("roles", roles)
                .issuedAt(nowInstant)
                .expiresAt(expInstant);
        if (roleTypes != null) {
            builder.claim("roleTypes", roleTypes);
        }
        if (dataScope != null) {
            builder.claim("dataScope", dataScope);
        }
        return builder.sign(secretKey);
    }

    /**
     * 用 ML-DSA-65（FIPS 204）手写 JWT 签名，因为 SmallRye JWT / jjwt 不支持该 alg。
     * token = base64url(header) "." base64url(payload) "." base64url(signature)，
     * 签名输入为 header.payload 的 ASCII 字节。
     */
    private String buildMlDsaAccessToken(String username, String roles, String roleTypes, String dataScope, long nowMs) {
        Map<String, Object> header = new LinkedHashMap<>();
        header.put("alg", ML_DSA_JWT_ALG);
        header.put("typ", "JWT");
        header.put("kid", mlDsaKeyRing.activeKid());

        long iat = nowMs / 1000L;
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("sub", username);
        payload.put("jti", UUID.randomUUID().toString());
        payload.put("roles", roles);
        payload.put("iat", iat);
        payload.put("exp", iat + accessTokenExpirationSeconds);
        if (roleTypes != null) {
            payload.put("roleTypes", roleTypes);
        }
        if (dataScope != null) {
            payload.put("dataScope", dataScope);
        }

        try {
            String headerB64 = base64UrlEncode(objectMapper.writeValueAsBytes(header));
            String payloadB64 = base64UrlEncode(objectMapper.writeValueAsBytes(payload));
            String signingInput = headerB64 + "." + payloadB64;
            byte[] signature = mlDsaSign(signingInput.getBytes(StandardCharsets.US_ASCII));
            return signingInput + "." + base64UrlEncode(signature);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to build ML-DSA token", ex);
        }
    }

    private byte[] mlDsaSign(byte[] signingInput) throws Exception {
        PrivateKey key = mlDsaKeyRing.activePrivateKey();
        if (key == null) {
            throw new IllegalStateException("No active ML-DSA signing key available");
        }
        Signature signer = Signature.getInstance(ML_DSA_ALGORITHM, BC);
        signer.initSign(key);
        signer.update(signingInput);
        return signer.sign();
    }

    /**
     * 统一解析：ML-DSA 模式手写校验，HS256 模式走 SmallRye JWTParser。
     */
    private Map<String, Object> claims(String token) throws ParseException {
        if (algorithm == JwtAlgorithm.ML_DSA_65) {
            return parseMlDsaClaims(token);
        }
        // HS256：先校验签名，再返回 claims 为 Map
        JsonWebToken jwt = jwtParser.verify(token, secretKey);
        Map<String, Object> result = new LinkedHashMap<>();
        for (String name : jwt.getClaimNames()) {
            Object value = jwt.getClaim(name);
            if (value != null) {
                result.put(name, value);
            }
        }
        return result;
    }

    private Map<String, Object> parseMlDsaClaims(String token) {
        int firstDot = token.indexOf('.');
        int secondDot = token.indexOf('.', firstDot + 1);
        if (firstDot < 0 || secondDot < 0) {
            throw new IllegalArgumentException("Invalid ML-DSA token structure");
        }

        String kid = null;
        try {
            byte[] headerBytes = base64UrlDecode(token.substring(0, firstDot));
            Map<String, Object> header = objectMapper.readValue(headerBytes, new TypeReference<Map<String, Object>>() {});
            Object alg = header.get("alg");
            if (alg == null || !ML_DSA_JWT_ALG.equals(alg.toString())) {
                throw new IllegalArgumentException("Invalid ML-DSA token algorithm: expected " + ML_DSA_JWT_ALG + " but got " + alg);
            }
            Object kidObj = header.get("kid");
            if (kidObj != null) {
                kid = String.valueOf(kidObj);
            }
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new IllegalArgumentException("Failed to parse ML-DSA token header", ex);
        }

        String signingInput = token.substring(0, secondDot); // header.payload
        byte[] signature = base64UrlDecode(token.substring(secondDot + 1));
        try {
            final String effectiveKid = kid;
            PublicKey verifyKey = mlDsaKeyRing.publicKeyFor(effectiveKid)
                    .orElseThrow(() -> new IllegalArgumentException(
                            "No verification key for ML-DSA kid=" + effectiveKid));
            Signature verifier = Signature.getInstance(ML_DSA_ALGORITHM, BC);
            verifier.initVerify(verifyKey);
            verifier.update(signingInput.getBytes(StandardCharsets.US_ASCII));
            if (!verifier.verify(signature)) {
                throw new IllegalArgumentException("Invalid ML-DSA signature");
            }
            byte[] payload = base64UrlDecode(token.substring(firstDot + 1, secondDot));
            Map<String, Object> parsedPayload = objectMapper.readValue(payload, new TypeReference<Map<String, Object>>() {
            });

            // Validate expiration
            Object expObj = parsedPayload.get("exp");
            if (expObj == null) {
                throw new IllegalArgumentException("ML-DSA token missing exp claim");
            }
            long expSeconds;
            if (expObj instanceof Number n) {
                expSeconds = n.longValue();
            } else {
                throw new IllegalArgumentException("ML-DSA token exp claim is not a number");
            }
            long nowSeconds = System.currentTimeMillis() / 1000L;
            if (nowSeconds > expSeconds) {
                throw new IllegalArgumentException("ML-DSA token has expired");
            }

            // Validate subject
            Object subObj = parsedPayload.get("sub");
            if (subObj == null || subObj.toString().isBlank()) {
                throw new IllegalArgumentException("ML-DSA token missing or empty sub claim");
            }

            // Validate iat (must not be significantly in the future)
            Object iatObj = parsedPayload.get("iat");
            if (iatObj instanceof Number iatNum) {
                long iatSeconds = iatNum.longValue();
                if (iatSeconds > nowSeconds + 300) {
                    throw new IllegalArgumentException("ML-DSA token has iat in the future");
                }
            }

            return parsedPayload;
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new IllegalArgumentException("Failed to parse ML-DSA token: " + ex.getMessage(), ex);
        }
    }

    // ---- key init ----

    private void initHmacSecret() {
        if (base64Secret == null || base64Secret.isBlank()) {
            throw new IllegalStateException("jwt.secret.key must be provided through JWT_SECRET and cannot be empty");
        }
        byte[] keyBytes;
        try {
            keyBytes = Base64.getDecoder().decode(base64Secret);
        } catch (IllegalArgumentException ex) {
            // 兼容：值不是 base64 时按原始 UTF-8 字节处理
            keyBytes = base64Secret.getBytes(StandardCharsets.UTF_8);
        }
        if (base64Secret.equals(FORBIDDEN_DEFAULT_SECRET)
                || keyBytes.length < MIN_HS256_SECRET_BYTES) {
            throw new IllegalStateException("jwt.secret.key must be a base64 of at least 32 bytes and not CHANGE_ME_IN_PRODUCTION");
        }
        this.secretKey = new SecretKeySpec(keyBytes, "HmacSHA256");
    }

    // ---- helpers ----

    private static String base64UrlEncode(byte[] bytes) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static byte[] base64UrlDecode(String s) {
        return Base64.getUrlDecoder().decode(s);
    }

    private static String claimStr(Map<String, Object> claims, String key) {
        Object value = claims.get(key);
        return value == null ? null : String.valueOf(value);
    }

    private static long claimExpMs(Map<String, Object> claims) {
        Object value = claims.get("exp");
        if (value instanceof Number n) {
            return n.longValue() * 1000L;
        }
        return 0L;
    }

    private List<String> normalizeRoleCodes(String roleCodes) {
        if (roleCodes == null) {
            return List.of();
        }
        return Arrays.stream(roleCodes.split(","))
                .map(this::normalizeRoleCode)
                .filter(code -> !code.isEmpty())
                .collect(Collectors.toList());
    }

    private String normalizeRoleCode(String roleCode) {
        if (roleCode == null) {
            return "";
        }
        String normalized = roleCode.trim().toUpperCase(Locale.ROOT);
        if (normalized.startsWith("ROLE_")) {
            return normalized.substring("ROLE_".length());
        }
        return normalized;
    }

    private boolean isRoleDefined(String roleCode) {
        return ROLE_SCHEMA.containsKey(roleCode);
    }

    private enum JwtAlgorithm {
        HS256,
        ML_DSA_65;

        static JwtAlgorithm from(String value) {
            if (value == null || value.isBlank()) {
                return HS256;
            }
            String normalized = value.trim().toUpperCase(Locale.ROOT).replace('-', '_');
            return JwtAlgorithm.valueOf(normalized);
        }
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
