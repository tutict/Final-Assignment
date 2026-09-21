package com.tutict.finalassignmentcloud.config.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.Set;

/**
 * 校验内部服务间调用的 X-Internal-Service-Token 请求头。
 *
 * /internal/ 路径必须带合法 token。其它路径若带合法 token，则提升为内部服务身份，
 * 以便 Feign 在登录等尚无用户 JWT 的场景下访问受保护接口。
 */
public class InternalServiceTokenFilter extends OncePerRequestFilter {

    public static final String HEADER = "X-Internal-Service-Token";
    private static final Set<String> WEAK_TOKENS = Set.of(
            "changeme", "change-me", "default", "secret", "password", "internal-service-token");

    private final byte[] expectedToken;

    public InternalServiceTokenFilter(String expectedToken) {
        if (expectedToken == null || expectedToken.isBlank()) {
            throw new IllegalStateException(
                    "internal.service-token must be provided through INTERNAL_SERVICE_TOKEN or configuration");
        }
        if (WEAK_TOKENS.contains(expectedToken.trim().toLowerCase(java.util.Locale.ROOT))) {
            throw new IllegalStateException("internal.service-token must not use a default or weak value");
        }
        this.expectedToken = expectedToken.getBytes(java.nio.charset.StandardCharsets.UTF_8);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String presented = request.getHeader(HEADER);
        boolean valid = constantTimeEquals(presented);
        if (isInternalPath(request) && !valid) {
            SecurityResponseWriter.writeStatus(response, HttpStatus.UNAUTHORIZED,
                    "UNAUTHORIZED", "Missing or invalid internal service token");
            return;
        }
        if (valid && SecurityContextHolder.getContext().getAuthentication() == null) {
            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                            "internal-service",
                            null,
                            List.of(
                                    new SimpleGrantedAuthority("ROLE_INTERNAL"),
                                    new SimpleGrantedAuthority("ROLE_ADMIN"),
                                    new SimpleGrantedAuthority("ADMIN"),
                                    new SimpleGrantedAuthority("ROLE_SUPER_ADMIN"),
                                    new SimpleGrantedAuthority("SUPER_ADMIN")));
            SecurityContextHolder.getContext().setAuthentication(authentication);
        }
        filterChain.doFilter(request, response);
    }

    private boolean isInternalPath(HttpServletRequest request) {
        String path = request.getRequestURI();
        return path != null && path.startsWith("/api/") && path.contains("/internal/");
    }

    private boolean constantTimeEquals(String presented) {
        if (presented == null) {
            return false;
        }
        byte[] other = presented.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        if (other.length != expectedToken.length) {
            return false;
        }
        int diff = 0;
        for (int i = 0; i < expectedToken.length; i++) {
            diff |= expectedToken[i] ^ other[i];
        }
        return diff == 0;
    }
}
