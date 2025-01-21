package finalassignmentbackend.config.login.jwt;

import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import io.smallrye.jwt.algorithm.SignatureAlgorithm;
import io.smallrye.jwt.auth.principal.JWTAuthContextInfo;
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
import java.time.Instant;
import java.util.Collections;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class TokenProvider {

    Logger log = Logger.getLogger(TokenProvider.class.getName());

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
        claimsBuilder.issuedAt(Instant.now()); // 设置签发时间为当前时间
        claimsBuilder.expiresIn(Duration.ofHours(24)); // 设置过期时间为 24 小时后
        claimsBuilder.issuer("tutict");
        claimsBuilder.audience("tutict_client");

        // 签名并生成 JWT
        return claimsBuilder.sign(key);
    }

    public boolean validateToken(String token) {
        try {
            Set<SignatureAlgorithm> permittedAlgorithms = Collections.singleton(SignatureAlgorithm.HS256);
            JWTAuthContextInfo contextInfo = new JWTAuthContextInfo(key, "tutict");
            contextInfo.setExpectedAudience(Collections.singleton("tutict_client"));
            contextInfo.setSignatureAlgorithm(permittedAlgorithms);

            JsonWebToken jwt = jwtParser.parse(token, contextInfo);

            return jwt.getIssuer().equals("tutict")
                    && jwt.getAudience().contains("tutict_client")
                    && jwt.getExpirationTime() > (System.currentTimeMillis() / 1000);
        } catch (ParseException e) {
            log.log(Level.WARNING, "Invalid token: " + e.getMessage(), e);
            return false;
        }
    }
}