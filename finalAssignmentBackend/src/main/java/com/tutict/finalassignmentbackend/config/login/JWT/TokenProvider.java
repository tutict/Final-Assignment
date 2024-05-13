package com.tutict.finalassignmentbackend.config.login.JWT;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Collection;
import java.util.Date;
import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
public class TokenProvider {

    // 过期时间24小时
    private static final long JWT_TOKEN_VALIDITY = 24 * 60 * 60 * 1000;

    // JWT Token的密钥
    @Value("${jwt.secret-key}")
    private String SECRET_KEY;
    private final Key key = Keys.hmacShaKeyFor(Decoders.BASE64.decode(SECRET_KEY));


    // 为用户生成JWT Token
    public String createToken(String username, Collection<? extends GrantedAuthority> authorities) {
        long now = System.currentTimeMillis();
        Date validity = new Date(now + JWT_TOKEN_VALIDITY);

        return Jwts.builder()
                .setSubject(username)
                .setIssuedAt(new Date(now))
                .setExpiration(validity)
                .signWith(key, SignatureAlgorithm.HS512)
                .claim("authorities", extractAuthorities(authorities))
                .compact();
    }

    // 从Token中提取用户名
    public String getUsernameFromToken(String token) {
        return getClaimFromToken(token, Claims::getSubject);
    }

    // 从Token中提取权限
    public List<String> getAuthoritiesFromToken(String token) {
        return getClaimFromToken(token, claims -> claims.get("authorities", List.class));
    }

    // 从Token中提取特定声明
    private <T> T getClaimFromToken(String token, Function<Claims, T> claimsResolver) {
        return claimsResolver.apply(getAllClaimsFromToken(token));
    }

    // 获取Token中的所有声明
    private Claims getAllClaimsFromToken(String token) {
       return Jwts.parser()
                   .setSigningKey(key)
                   .build()
                   .parseClaimsJws(token)
                   .getBody();
    }

    // 验证Token是否仍然有效
    public boolean validateToken(String token) {
        // 从Token中获取用户名
        String username = getUsernameFromToken(token);

        // 检查用户名是否存在，如果存在，继续验证Token是否过期
        if (username != null) {
            return !isTokenExpired(token);
        }

        return false;
    }

    // 检查Token是否过期
    private boolean isTokenExpired(String token) {
        return getClaimFromToken(token, Claims::getExpiration).before(new Date());
    }

    // 根据Token创建Authentication对象
    public Authentication getAuthentication(String token) {
        String username = getUsernameFromToken(token);
        List<String> authorityStrings = getAuthoritiesFromToken(token);

        // 将字符串列表转换为GrantedAuthority集合
        List<GrantedAuthority> grantedAuthorities = authorityStrings.stream()
                .map(SimpleGrantedAuthority::new)
                .collect(Collectors.toList());

        // 使用转换后的GrantedAuthority集合创建UsernamePasswordAuthenticationToken
        return new UsernamePasswordAuthenticationToken(username, null, grantedAuthorities);
    }

    // 将GrantedAuthority集合转换为String列表
    private List<String> extractAuthorities(Collection<? extends GrantedAuthority> authorities) {
        return authorities.stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toList());
    }
}