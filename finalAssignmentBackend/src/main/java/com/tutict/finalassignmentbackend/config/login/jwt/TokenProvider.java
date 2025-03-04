package com.tutict.finalassignmentbackend.config.login.jwt;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;

import javax.crypto.SecretKey;
import java.util.Base64;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Service
public class TokenProvider {

    private static final Logger LOG = Logger.getLogger(TokenProvider.class.getName());

    @Value("${jwt.secret.key}")
    private String base64Secret;

    private SecretKey secretKey;

    @PostConstruct
    public void init() {
        // 将 Base64 编码的密钥解码为 byte 数组
        byte[] keyBytes = Base64.getDecoder().decode(base64Secret);
        // 使用 Keys 工具类生成用于 HMACSHA256 的 SecretKey
        this.secretKey = Keys.hmacShaKeyFor(keyBytes);
        LOG.info("TokenProvider initialized with HS256 secret key");
    }

    /**
     * 创建 JWT 令牌，并将角色作为 claim 存入
     *
     * @param username 用户名（主体）
     * @param roles    用户角色，如 "USER" 或 "ADMIN"，多个角色以逗号分隔
     * @return 生成的 JWT 令牌
     */
    public String createToken(String username, String roles) {
        long now = System.currentTimeMillis();
        Date expirationDate = new Date(now + 86400000L); // 令牌有效期 24 小时

        return Jwts.builder()
                .subject(username)
                .claim("roles", roles) // 将角色加入到 token 中
                .issuedAt(new Date(now))
                .expiration(expirationDate)
                .signWith(secretKey)
                .compact();
    }

    /**
     * 验证 JWT 令牌
     *
     * @param token 令牌字符串
     * @return 若令牌有效返回 true，否则返回 false
     */
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token);
            LOG.log(Level.INFO, "Token validated successfully: " + token);
            return true;
        } catch (JwtException e) {
            LOG.log(Level.WARNING, "Invalid token: " + e.getMessage(), e);
            return false;
        }
    }

    /**
     * 从 JWT 中提取角色列表
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
            LOG.log(Level.WARNING, "Failed to extract roles from token: " + e.getMessage(), e);
            return List.of();
        }
    }

    public String getUsernameFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
        return claims.getSubject();
    }
}
