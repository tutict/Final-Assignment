package finalassignmentbackend.config.login.jwt;

import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import io.smallrye.jwt.auth.principal.JWTParser;
import io.smallrye.jwt.auth.principal.ParseException;
import io.smallrye.jwt.build.Jwt;
import io.smallrye.jwt.build.JwtClaimsBuilder;
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.ConfigProvider;
import org.eclipse.microprofile.jwt.JsonWebToken;

import javax.crypto.SecretKey;
import java.time.Duration;
@ApplicationScoped
public class TokenProvider {

    @Inject
    JWTParser jwtParser;

    private SecretKey key;

    @PostConstruct
    public void init() {
        // 使用 ConfigProvider 来读取配置
        String keyFromConfig = ConfigProvider.getConfig().getValue("jwt.secret.key", String.class);
        if (keyFromConfig == null || keyFromConfig.isEmpty()) {
            throw new IllegalArgumentException("Secret key is not properly configured");
        }

        System.out.println("Loaded secret key from ConfigProvider: " + keyFromConfig);

        // Decode the base64-encoded secret key
        byte[] keyBytes = Decoders.BASE64.decode(keyFromConfig);
        this.key = Keys.hmacShaKeyFor(keyBytes);
    }

    public String createToken(String username, String roles) {
        JwtClaimsBuilder claimsBuilder = Jwt.claims();
        claimsBuilder.subject(username);
        claimsBuilder.groups(roles);
        claimsBuilder.issuedAt(System.currentTimeMillis() / 1000);
        claimsBuilder.expiresAt(System.currentTimeMillis() / 1000 + Duration.ofHours(24).getSeconds());
        claimsBuilder.issuer("tutict");
        claimsBuilder.audience("tutict_client");

        // Use the correct key to sign the JWT
        return claimsBuilder.sign(key);
    }

    public boolean validateToken(String token) {
        try {
            JsonWebToken jwt = jwtParser.parse(token);
            // Validate issuer, audience, and expiration time
            return jwt.getIssuer().equals("tutict")
                    && jwt.getAudience().contains("tutict_client")
                    && jwt.getExpirationTime() > (System.currentTimeMillis() / 1000);
        } catch (ParseException e) {
            // Log invalid token or specific error
            System.err.println("Invalid token: " + e.getMessage());
            return false;
        }
    }
}