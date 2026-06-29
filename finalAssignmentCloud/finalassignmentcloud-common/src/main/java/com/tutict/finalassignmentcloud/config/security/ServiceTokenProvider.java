package com.tutict.finalassignmentcloud.config.security;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.config.security.pqc.PqcProviderInitializer;
import com.tutict.finalassignmentcloud.enums.DataScope;
import com.tutict.finalassignmentcloud.enums.RoleType;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

import javax.crypto.SecretKey;
import java.io.StringReader;
import java.nio.charset.StandardCharsets;
import java.security.PublicKey;
import java.security.Signature;
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

import org.bouncycastle.asn1.x509.SubjectPublicKeyInfo;
import org.bouncycastle.cert.X509CertificateHolder;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.openssl.PEMParser;
import org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter;

public class ServiceTokenProvider {

    private static final Logger LOG = Logger.getLogger(ServiceTokenProvider.class.getName());
    private static final String BC = BouncyCastleProvider.PROVIDER_NAME;
    private static final String ML_DSA_ALGORITHM = "ML-DSA-65";
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
    private final JwtAlgorithm algorithm;
    private final PublicKey mlDsaPublicKey;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public ServiceTokenProvider(String base64Secret) {
        this(base64Secret, "HS256", null);
    }

    public ServiceTokenProvider(String base64Secret, String algorithm, String mlDsaPublicKeyPem) {
        PqcProviderInitializer.ensureBouncyCastle();
        this.algorithm = JwtAlgorithm.from(algorithm);
        if (this.algorithm == JwtAlgorithm.ML_DSA_65) {
            this.secretKey = null;
            this.mlDsaPublicKey = loadMlDsaPublicKey(mlDsaPublicKeyPem);
        } else {
            validateSecret(base64Secret);
            byte[] keyBytes = Base64.getDecoder().decode(base64Secret);
            this.secretKey = Keys.hmacShaKeyFor(keyBytes);
            this.mlDsaPublicKey = null;
        }
    }

    public boolean validateToken(String token) {
        try {
            claims(token);
            return true;
        } catch (JwtException | IllegalArgumentException ex) {
            LOG.log(Level.WARNING, "Invalid JWT: {0}", ex.getMessage());
            return false;
        }
    }

    public String getUsernameFromToken(String token) {
        return claimStr(claims(token), "sub");
    }

    public List<String> extractRoles(String token) {
        try {
            String roles = claimStr(claims(token), "roles");
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

    private Map<String, Object> claims(String token) {
        if (algorithm == JwtAlgorithm.ML_DSA_65) {
            return parseMlDsaClaims(token);
        }
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private Map<String, Object> parseMlDsaClaims(String token) {
        int firstDot = token.indexOf('.');
        int secondDot = token.indexOf('.', firstDot + 1);
        if (firstDot < 0 || secondDot < 0) {
            throw new IllegalArgumentException("Invalid ML-DSA token structure");
        }
        String signingInput = token.substring(0, secondDot);
        byte[] signature = Base64.getUrlDecoder().decode(token.substring(secondDot + 1));
        try {
            Signature verifier = Signature.getInstance(ML_DSA_ALGORITHM, BC);
            verifier.initVerify(mlDsaPublicKey);
            verifier.update(signingInput.getBytes(StandardCharsets.US_ASCII));
            if (!verifier.verify(signature)) {
                throw new IllegalArgumentException("Invalid ML-DSA signature");
            }
            byte[] payload = Base64.getUrlDecoder().decode(token.substring(firstDot + 1, secondDot));
            return objectMapper.readValue(payload, new TypeReference<Map<String, Object>>() {
            });
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new IllegalArgumentException("Failed to parse ML-DSA token: " + ex.getMessage(), ex);
        }
    }

    private PublicKey loadMlDsaPublicKey(String pem) {
        if (pem == null || pem.isBlank()) {
            throw new IllegalStateException("jwt.ml-dsa.public-key must be configured for ML-DSA-65 verification");
        }
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
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to load ML-DSA public key", ex);
        }
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

    private void validateSecret(String secret) {
        if (secret == null || secret.isBlank()) {
            throw new IllegalStateException("jwt.secret.key must be provided through configuration or JWT_SECRET_KEY");
        }
        String normalized = secret.trim().toLowerCase(Locale.ROOT);
        if (Set.of("secret", "changeme", "change-me", "default", "root", "password").contains(normalized)) {
            throw new IllegalStateException("jwt.secret.key must not use a default or weak value");
        }
    }

    private static String claimStr(Map<String, Object> claims, String key) {
        Object value = claims.get(key);
        return value == null ? null : String.valueOf(value);
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

    private record RoleMetadata(RoleType roleType, DataScope dataScope) {
    }
}
