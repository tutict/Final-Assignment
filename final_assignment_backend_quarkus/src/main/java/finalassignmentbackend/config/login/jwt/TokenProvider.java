package finalassignmentbackend.config.login.jwt;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import javax.crypto.SecretKey;
import java.util.Arrays;
import java.util.Base64;
import java.util.Date;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

// Quarkus服务类，用于处理JWT的创建、验证和解析
@ApplicationScoped
public class TokenProvider {

    // 日志记录器，用于记录JWT处理过程中的信息
    private static final Logger LOG = Logger.getLogger(TokenProvider.class.getName());

    // 注入配置属性：JWT密钥（Base64编码）
    @ConfigProperty(name = "jwt.secret.key")
    String base64Secret;

    // JWT签名使用的密钥
    private SecretKey secretKey;

    // 初始化方法，解码Base64密钥并生成SecretKey
    @PostConstruct
    public void init() {
        // 将Base64编码的密钥解码为字节数组
        byte[] keyBytes = Base64.getDecoder().decode(base64Secret);
        // 使用Keys工具类生成HMAC-SHA256的SecretKey
        this.secretKey = Keys.hmacShaKeyFor(keyBytes);
        LOG.info("TokenProvider已初始化，使用HS256密钥");
    }

    /**
     * 创建JWT令牌，并将角色作为claim存入
     *
     * @param username 用户名（主体）
     * @param roles    用户角色，如 "USER" 或 "ADMIN"，多个角色以逗号分隔
     * @return 生成的JWT令牌
     */
    public String createToken(String username, String roles) {
        long now = System.currentTimeMillis();
        Date expirationDate = new Date(now + 86400000L); // 令牌有效期24小时

        return Jwts.builder()
                .subject(username)
                .claim("roles", roles) // 将角色加入到token中
                .issuedAt(new Date(now))
                .expiration(expirationDate)
                .signWith(secretKey)
                .compact();
    }

    /**
     * 验证JWT令牌
     *
     * @param token 令牌字符串
     * @return 若令牌有效返回true，否则返回false
     */
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token);
            LOG.log(Level.INFO, "令牌验证成功: {0}", token);
            return true;
        } catch (JwtException e) {
            LOG.log(Level.WARNING, "无效的令牌: {0}", e.getMessage());
            return false;
        }
    }

    /**
     * 从JWT中提取角色列表
     *
     * @param token 令牌字符串
     * @return 角色列表，例如 ["ROLE_USER", "ROLE_ADMIN"]
     */
    public List<String> extractRoles(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            String roles = claims.get("roles", String.class);
            if (roles != null && !roles.isEmpty()) {
                return Arrays.stream(roles.split(","))
                        .map(String::trim)
                        .map(role -> "ROLE_" + role)
                        .collect(Collectors.toList());
            }
            return List.of();
        } catch (JwtException e) {
            LOG.log(Level.WARNING, "从令牌提取角色失败: {0}", e.getMessage());
            return List.of();
        }
    }

    /**
     * 从JWT中提取用户名
     *
     * @param token 令牌字符串
     * @return 用户名
     */
    public String getUsernameFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
        return claims.getSubject();
    }
}