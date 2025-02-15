package finalassignmentbackend.config.login.jwt;

import io.smallrye.jwt.build.Jwt;
import io.smallrye.jwt.build.JwtClaimsBuilder;
import io.smallrye.jwt.auth.principal.JWTParser;
import io.smallrye.jwt.auth.principal.ParseException;
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.jwt.JsonWebToken;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class TokenProvider {

    private static final Logger LOG = Logger.getLogger(TokenProvider.class.getName());

    @ConfigProperty(name = "jwt.secret.key")
    String base64Secret;

    private SecretKey secretKey;

    @Inject
    JWTParser jwtParser; // Quarkus 提供，用于手动解析 Token

    @PostConstruct
    public void init() {
        // 将 Base64 字符串解码成字节数组
        byte[] keyBytes = Base64.getDecoder().decode(base64Secret);
        // 指定使用 "HmacSHA256" 算法
        this.secretKey = new SecretKeySpec(keyBytes, "HmacSHA256");

        LOG.info("TokenProvider initialized with HS256 secret key, size=" + keyBytes.length + " bytes");
    }

    /**
     * 使用 SmallRye JWT 构建并签发 Token。
     *
     * @param username 用户名/subject
     * @param roles    用户角色，可用 Set<String> 表示
     * @return 生成的 JWT 字符串
     */
    public String createToken(String username, String roles) {
        // 构建 Claims
        JwtClaimsBuilder claimsBuilder = Jwt.issuer("tutict")
                .audience("tutict_client")
                .subject(username)
                .groups(roles)             // 设置角色
                .issuedAt(Instant.now())   // 设置签发时间
                .expiresIn(Duration.ofHours(24)); // 过期时间 24h

        // 使用对称密钥进行签名 (HS256)
        return claimsBuilder.sign(secretKey);
    }

    /**
     * 手动验证 Token（websocket）
     */
    public boolean validateToken(String token) {
        try {
            // 如果 Token 不合法或过期，会抛出 ParseException
            JsonWebToken jwt = jwtParser.parse(token);
            // 如果 parse 成功，说明签名、issuer、audience、expires 都合法
            return true;
        } catch (ParseException e) {
            LOG.log(Level.WARNING, "Invalid token: " + e.getMessage(), e);
            return false;
        }
    }
}
