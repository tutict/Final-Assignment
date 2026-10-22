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

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * 校验内部服务间调用的 X-Internal-Service-Token 请求头。
 *
 * <p>路径含 internal 段时必须携带合法 token，并以内部服务身份（ROLE_INTERNAL）执行；
 * 其它路径携带合法 token 时同样只授予 ROLE_INTERNAL，不再隐式提升为管理员身份，
 * 因此面向用户的接口无法借由内部令牌越权。
 */
public class InternalServiceTokenFilter extends OncePerRequestFilter {

    public static final String HEADER = "X-Internal-Service-Token";
    public static final String ROLE_INTERNAL = "INTERNAL";
    public static final String INTERNAL_PRINCIPAL = "internal-service";

    private static final String INTERNAL_SEGMENT = "internal";
    private static final Set<String> WEAK_TOKENS = Set.of(
            "changeme", "change-me", "default", "secret", "password", "internal-service-token");

    private final byte[] expectedToken;

    public InternalServiceTokenFilter(String expectedToken) {
        if (expectedToken == null || expectedToken.isBlank()) {
            throw new IllegalStateException(
                    "internal.service-token must be provided through INTERNAL_SERVICE_TOKEN or configuration");
        }
        if (WEAK_TOKENS.contains(expectedToken.trim().toLowerCase(Locale.ROOT))) {
            throw new IllegalStateException("internal.service-token must not use a default or weak value");
        }
        this.expectedToken = expectedToken.getBytes(StandardCharsets.UTF_8);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        boolean internalPath = isInternalPath(request);
        boolean valid = constantTimeEquals(request.getHeader(HEADER));
        if (internalPath && !valid) {
            SecurityResponseWriter.writeStatus(response, HttpStatus.UNAUTHORIZED,
                    "UNAUTHORIZED", "Missing or invalid internal service token");
            return;
        }
        if (valid && (internalPath || SecurityContextHolder.getContext().getAuthentication() == null)) {
            SecurityContextHolder.getContext().setAuthentication(internalAuthentication());
        }
        filterChain.doFilter(request, response);
    }

    private UsernamePasswordAuthenticationToken internalAuthentication() {
        return new UsernamePasswordAuthenticationToken(
                INTERNAL_PRINCIPAL,
                null,
                List.of(
                        new SimpleGrantedAuthority("ROLE_" + ROLE_INTERNAL),
                        new SimpleGrantedAuthority(ROLE_INTERNAL)));
    }

    /**
     * 归一化请求路径后按段判断是否命中 internal，避免百分号编码、路径参数与相对路径绕过令牌校验。
     */
    static boolean isInternalPath(HttpServletRequest request) {
        String normalized = normalizePath(request.getRequestURI(), request.getContextPath());
        for (String segment : normalized.split("/")) {
            if (INTERNAL_SEGMENT.equals(segment)) {
                return true;
            }
        }
        return false;
    }

    /**
     * 逐段解码百分号转义、剥离矩阵参数（;name=value）、折叠空段并解析相对路径，得到与 Spring 路由一致的路径。
     */
    static String normalizePath(String rawUri, String contextPath) {
        if (rawUri == null || rawUri.isEmpty()) {
            return "";
        }
        String path = rawUri;
        if (contextPath != null && !contextPath.isEmpty() && path.startsWith(contextPath)) {
            path = path.substring(contextPath.length());
        }
        Deque<String> segments = new ArrayDeque<>();
        for (String rawSegment : path.split("/", -1)) {
            String segment = stripMatrixParameters(percentDecode(rawSegment));
            if (segment.isEmpty() || ".".equals(segment)) {
                continue;
            }
            if ("..".equals(segment)) {
                if (!segments.isEmpty()) {
                    segments.removeLast();
                }
                continue;
            }
            segments.addLast(segment);
        }
        return "/" + String.join("/", segments);
    }

    private static String stripMatrixParameters(String segment) {
        int semicolon = segment.indexOf(';');
        return semicolon < 0 ? segment : segment.substring(0, semicolon);
    }

    /**
     * 仅解码 %XX 转义，保留字面量 '+'（路径中的加号不是空格）。
     */
    private static String percentDecode(String segment) {
        if (segment.indexOf('%') < 0) {
            return segment;
        }
        ByteArrayOutputStream decoded = new ByteArrayOutputStream(segment.length());
        for (int i = 0; i < segment.length(); i++) {
            char current = segment.charAt(i);
            if (current == '%' && i + 2 < segment.length()) {
                int high = Character.digit(segment.charAt(i + 1), 16);
                int low = Character.digit(segment.charAt(i + 2), 16);
                if (high >= 0 && low >= 0) {
                    decoded.write((high << 4) + low);
                    i += 2;
                    continue;
                }
            }
            decoded.writeBytes(String.valueOf(current).getBytes(StandardCharsets.UTF_8));
        }
        return new String(decoded.toByteArray(), StandardCharsets.UTF_8);
    }

    private boolean constantTimeEquals(String presented) {
        if (presented == null) {
            return false;
        }
        byte[] other = presented.getBytes(StandardCharsets.UTF_8);
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
