package com.tutict.finalassignmentbackend.config.login.jwt;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.security.pqc.PqcProviderInitializer;
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
import java.io.StringReader;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.Signature;
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
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

import org.bouncycastle.asn1.pkcs.PrivateKeyInfo;
import org.bouncycastle.asn1.x509.SubjectPublicKeyInfo;
import org.bouncycastle.cert.X509CertificateHolder;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.openssl.PEMParser;
import org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter;

@Service
public class TokenProvider {

    private static final Logger LOG = Logger.getLogger(TokenProvider.class.getName());
    private static final String FORBIDDEN_DEFAULT_SECRET = "CHANGE_ME_IN_PRODUCTION";
    private static final int MIN_HS256_SECRET_BYTES = 32;
    private static final String BC = BouncyCastleProvider.PROVIDER_NAME;
    private static final String ML_DSA_ALGORITHM = "ML-DSA-65";   // BC KeyPairGenerator / Signature
    private static final String ML_DSA_JWT_ALG = "ML-DSA-65";     // JWT header alg

    @Value("${jwt.secret:}")
    private String secret;

    @Value("${jwt.algorithm:HS256}")
    private String configuredAlgorithm;

    @Value("${jwt.private-key:}")
    private String privateKeyPem;

    @Value("${jwt.public-key:}")
    private String publicKeyPem;

    @Value("${jwt.ml-dsa.private-key:}")
    private String mlDsaPrivateKeyPem;

    @Value("${jwt.ml-dsa.public-key:}")
    private String mlDsaPublicKeyPem;

    @Value("${jwt.access-token-expiration:3600}")
    private long accessTokenExpirationSeconds;

    private JwtAlgorithm algorithm;
    private SecretKey secretKey;
    private PrivateKey privateKey;
    private PublicKey publicKey;
    private PrivateKey mlDsaPrivateKey;
    private PublicKey mlDsaPublicKey;
    private final ObjectMapper objectMapper = new ObjectMapper();

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
        switch (algorithm) {
            case RS256 -> initRsaKeys();
            case ML_DSA_65 -> initMlDsaKeys();
            default -> initHmacSecret();
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
        Map<String, Object> claims = claims(token);
        long expMs = claimExpMs(claims);
        return Math.max(expMs - System.currentTimeMillis(), 0L);
    }

    public long getAccessTokenExpirationSeconds() {
        return accessTokenExpirationSeconds;
    }

    public boolean validateToken(String token) {
        try {
            claims(token);
            LOG.log(Level.FINE, "Token validated successfully");
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            LOG.log(Level.WARNING, "Invalid token: " + e.getMessage(), e);
            return false;
        }
    }

    public List<String> extractRoles(String token) {
        try {
            String roles = claimStr(claims(token), "roles");
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
        return claimStr(claims(token), "sub");
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
        } catch (JwtException | IllegalArgumentException e) {
            LOG.log(Level.WARNING, "Failed to extract role types from token: " + e.getMessage(), e);
            return List.of();
        }
    }

    public DataScope extractDataScope(String token) {
        try {
            String dataScope = claimStr(claims(token), "dataScope");
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

    // ---- token build / parse ----

    private String buildAccessToken(String username, String roles, String roleTypes, String dataScope) {
        long now = System.currentTimeMillis();
        if (algorithm == JwtAlgorithm.ML_DSA_65) {
            return buildMlDsaAccessToken(username, roles, roleTypes, dataScope, now);
        }
        Date issuedAt = new Date(now);
        Date expirationDate = new Date(now + accessTokenExpirationSeconds * 1000L);

        JwtBuilder builder = Jwts.builder()
                .subject(username)
                .id(UUID.randomUUID().toString())
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

    /**
     * 用 ML-DSA-65（FIPS 204）手写 JWT 签名，因为 jjwt 不支持该 alg。
     * token = base64url(header) "." base64url(payload) "." base64url(signature)，
     * 签名输入为 header.payload 的 ASCII 字节。
     */
    private String buildMlDsaAccessToken(String username, String roles, String roleTypes, String dataScope, long nowMs) {
        Map<String, Object> header = new LinkedHashMap<>();
        header.put("alg", ML_DSA_JWT_ALG);
        header.put("typ", "JWT");

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
        Signature signer = Signature.getInstance(ML_DSA_ALGORITHM, BC);
        signer.initSign(mlDsaPrivateKey);
        signer.update(signingInput);
        return signer.sign();
    }

    private Map<String, Object> claims(String token) {
        if (algorithm == JwtAlgorithm.ML_DSA_65) {
            return parseMlDsaClaims(token);
        }
        return parseClaims(token);
    }

    private Map<String, Object> parseMlDsaClaims(String token) {
        int firstDot = token.indexOf('.');
        int secondDot = token.indexOf('.', firstDot + 1);
        if (firstDot < 0 || secondDot < 0) {
            throw new IllegalArgumentException("Invalid ML-DSA token structure");
        }
        String signingInput = token.substring(0, secondDot); // header.payload
        byte[] signature = base64UrlDecode(token.substring(secondDot + 1));
        try {
            Signature verifier = Signature.getInstance(ML_DSA_ALGORITHM, BC);
            verifier.initVerify(mlDsaPublicKey);
            verifier.update(signingInput.getBytes(StandardCharsets.US_ASCII));
            if (!verifier.verify(signature)) {
                throw new IllegalArgumentException("Invalid ML-DSA signature");
            }
            byte[] payload = base64UrlDecode(token.substring(firstDot + 1, secondDot));
            return objectMapper.readValue(payload, new TypeReference<Map<String, Object>>() {
            });
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new IllegalArgumentException("Failed to parse ML-DSA token: " + ex.getMessage(), ex);
        }
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

    // ---- key init ----

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

    private void initMlDsaKeys() {
        PqcProviderInitializer.ensureBouncyCastle();
        try {
            if (isPresent(mlDsaPrivateKeyPem) && isPresent(mlDsaPublicKeyPem)) {
                this.mlDsaPrivateKey = loadPemPrivateKey(mlDsaPrivateKeyPem);
                this.mlDsaPublicKey = loadPemPublicKey(mlDsaPublicKeyPem);
            } else {
                KeyPairGenerator kpg = KeyPairGenerator.getInstance(ML_DSA_ALGORITHM, BC);
                KeyPair kp = kpg.generateKeyPair();
                this.mlDsaPrivateKey = kp.getPrivate();
                this.mlDsaPublicKey = kp.getPublic();
                LOG.warning("No ML-DSA keys configured (jwt.ml-dsa.private-key/public-key); "
                        + "generated ephemeral keypair. Tokens will NOT survive a restart.");
            }
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to initialize ML-DSA keys", ex);
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

    private PrivateKey loadPemPrivateKey(String pem) throws Exception {
        try (PEMParser parser = new PEMParser(new StringReader(pem))) {
            Object obj = parser.readObject();
            if (obj instanceof PrivateKeyInfo pki) {
                return new JcaPEMKeyConverter().setProvider(BC).getPrivateKey(pki);
            }
            throw new IllegalArgumentException("PEM is not a PKCS#8 private key: " + obj);
        }
    }

    private PublicKey loadPemPublicKey(String pem) throws Exception {
        try (PEMParser parser = new PEMParser(new StringReader(pem))) {
            Object obj = parser.readObject();
            JcaPEMKeyConverter conv = new JcaPEMKeyConverter().setProvider(BC);
            if (obj instanceof SubjectPublicKeyInfo spki) {
                return conv.getPublicKey(spki);
            }
            if (obj instanceof X509CertificateHolder cert) {
                return conv.getPublicKey(cert.getSubjectPublicKeyInfo());
            }
            throw new IllegalArgumentException("PEM is not a public key: " + obj);
        }
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
        if (value instanceof Date d) {
            return d.getTime();
        }
        if (value instanceof Number n) {
            return n.longValue() * 1000L;
        }
        return 0L;
    }

    private static boolean isPresent(String s) {
        return s != null && !s.isBlank();
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
        RS256,
        ML_DSA_65;

        static JwtAlgorithm from(String value) {
            if (value == null || value.isBlank()) {
                return HS256;
            }
            String normalized = value.trim().toUpperCase(Locale.ROOT).replace('-', '_');
            return JwtAlgorithm.valueOf(normalized);
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
