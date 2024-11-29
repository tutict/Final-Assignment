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

import javax.crypto.SecretKey;
import java.security.SecureRandom;
import java.time.Duration;
import java.util.Base64;
import java.util.Set;

@ApplicationScoped
public class TokenProvider {

    @Inject
    JWTParser jwtParser;

    // Secret key for JWT
    private final String secretKeyBase64 = Base64.getEncoder().encodeToString(new SecureRandom().generateSeed(32));

    private SecretKey key;

    @PostConstruct
    public void init() {
        // Decode the base64-encoded secret key
        byte[] keyBytes = Decoders.BASE64.decode(secretKeyBase64);
        this.key = Keys.hmacShaKeyFor(keyBytes);
    }

    public String createToken(String username, Set<String> roles) {
        JwtClaimsBuilder claimsBuilder = Jwt.claims();
        claimsBuilder.subject(username);
        claimsBuilder.groups(roles); // 设置用户角色
        claimsBuilder.issuedAt(System.currentTimeMillis() / 1000);
        claimsBuilder.expiresAt(System.currentTimeMillis() / 1000 + Duration.ofHours(24).getSeconds());
        claimsBuilder.sign(key);
        return claimsBuilder.sign();
    }

    public boolean validateToken(String token) {
        try {
            jwtParser.parse(token);
            return true;
        } catch (ParseException e) {
            // 无效的 JWT 令牌
            return false;
        }
    }
}
