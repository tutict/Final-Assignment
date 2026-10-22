package finalassignmentbackend.config.login.jwt;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.quarkus.runtime.LaunchMode;
import io.quarkus.runtime.StartupEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.Config;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;

/**
 * Signing and HTTP verification must use the same HMAC key. A partial rotation makes every
 * freshly issued token fail verification (and can leave a known repository key trusted).
 */
@ApplicationScoped
public class JwtConfigConsistencyValidator {

    private static final String DEV_SECRET = "dev-jwt-secret-key-for-local-startup-please-change-1234567890";
    private static final int MIN_HMAC_KEY_BYTES = 32;

    @Inject
    Config config;

    void onStart(@Observes StartupEvent event) {
        String algorithm = config.getOptionalValue("jwt.algorithm", String.class).orElse("HS256");
        if (!"HS256".equalsIgnoreCase(algorithm)) {
            return;
        }

        String secret = config.getOptionalValue("jwt.secret.key", String.class).orElse("").trim();
        if (secret.isEmpty()) {
            throw new IllegalStateException(
                    "jwt.secret.key is required for HS256 (set JWT_SECRET_KEY or JWT_SECRET)");
        }
        if (LaunchMode.current() == LaunchMode.NORMAL && DEV_SECRET.equals(secret)) {
            throw new IllegalStateException(
                    "Refusing to start with the repository dev JWT secret; set JWT_SECRET_KEY and JWT_VERIFY_JWK");
        }

        byte[] signingKey = hmacKeyBytes(secret);
        if (signingKey.length < MIN_HMAC_KEY_BYTES) {
            throw new IllegalStateException("jwt.secret.key must resolve to at least 32 HMAC key bytes");
        }

        byte[] verificationKey = verificationKeyBytes();
        if (!MessageDigest.isEqual(signingKey, verificationKey)) {
            throw new IllegalStateException(
                    "smallrye.jwt.verify.secretkey does not match jwt.secret.key; "
                            + "rotate JWT_SECRET_KEY and JWT_VERIFY_JWK together "
                            + "(JWK k = base64url of the HMAC key bytes)");
        }
    }

    private byte[] verificationKeyBytes() {
        String jwk = config.getOptionalValue("smallrye.jwt.verify.secretkey", String.class).orElse("").trim();
        if (jwk.isEmpty()) {
            throw new IllegalStateException("smallrye.jwt.verify.secretkey is required (set JWT_VERIFY_JWK)");
        }
        try {
            JsonNode node = new ObjectMapper().readTree(jwk);
            if (!"oct".equals(node.path("kty").asText())) {
                throw new IllegalStateException("smallrye.jwt.verify.secretkey must be an oct JWK for HS256");
            }
            String k = node.path("k").asText("");
            if (k.isEmpty()) {
                throw new IllegalStateException("smallrye.jwt.verify.secretkey is missing the k field");
            }
            return Base64.getUrlDecoder().decode(k);
        } catch (IllegalArgumentException ex) {
            throw new IllegalStateException("smallrye.jwt.verify.secretkey is not a valid oct JWK", ex);
        } catch (Exception ex) {
            throw new IllegalStateException("smallrye.jwt.verify.secretkey is not valid JSON", ex);
        }
    }

    /** Mirrors TokenProvider: standard Base64 is decoded, anything else is used as UTF-8 bytes. */
    private static byte[] hmacKeyBytes(String secret) {
        try {
            return Base64.getDecoder().decode(secret);
        } catch (IllegalArgumentException ex) {
            return secret.getBytes(StandardCharsets.UTF_8);
        }
    }
}
