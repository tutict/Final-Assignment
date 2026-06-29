package com.tutict.finalassignmentcloud.config.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Set;

/**
 * 校验内部服务间调用的 X-Internal-Service-Token 请求头。
 *
 * 仅对 /api 下含 /internal/ 段的路径生效（这些路径在 Spring Security 层通常 permitAll，
 * 由本过滤器用共享 service token 强校验）。缺失或不匹配返回 401。非 internal 路径直接放行。
 *
 * token 通过构造器注入，启动时空或弱值即抛异常（fail-fast，与 jwt.secret.key 一致）。
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
        if (!isInternalPath(request)) {
            filterChain.doFilter(request, response);
            return;
        }
        String presented = request.getHeader(HEADER);
        if (!constantTimeEquals(presented)) {
            SecurityResponseWriter.writeStatus(response, HttpStatus.UNAUTHORIZED,
                    "UNAUTHORIZED", "Missing or invalid internal service token");
            return;
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
