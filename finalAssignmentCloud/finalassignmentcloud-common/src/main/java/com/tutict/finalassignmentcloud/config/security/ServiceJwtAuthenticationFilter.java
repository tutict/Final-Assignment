package com.tutict.finalassignmentcloud.config.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.connection.RedisConnection;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

public class ServiceJwtAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger LOG = LoggerFactory.getLogger(ServiceJwtAuthenticationFilter.class);

    private final ServiceTokenProvider tokenProvider;
    private final RedisConnectionFactory redisConnectionFactory;
    private final Runnable dependencyTimeout;
    private final ConcurrentHashMap<String, Long> localRevocations = new ConcurrentHashMap<>();

    public ServiceJwtAuthenticationFilter(ServiceTokenProvider tokenProvider) {
        this(tokenProvider, null);
    }

    public ServiceJwtAuthenticationFilter(ServiceTokenProvider tokenProvider,
                                          RedisConnectionFactory redisConnectionFactory) {
        this(tokenProvider, redisConnectionFactory, null);
    }

    public ServiceJwtAuthenticationFilter(ServiceTokenProvider tokenProvider,
                                          RedisConnectionFactory redisConnectionFactory,
                                          Runnable dependencyTimeout) {
        this.tokenProvider = tokenProvider;
        this.redisConnectionFactory = redisConnectionFactory;
        this.dependencyTimeout = dependencyTimeout;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String jwt = getJwtFromRequest(request);
        if (jwt != null && redisConnectionFactory != null) {
            ServiceRevocation.Verdict verdict = ServiceRevocation.inspect(localRevocations, jwt, lookup(jwt));
            if (ServiceRevocation.denied(verdict)) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType("application/json");
                response.getWriter().write("{\"errorCode\":\"UNAUTHORIZED\"}");
                return;
            }
            if (ServiceRevocation.shed(request.getMethod(), request.getRequestURI(), verdict)) {
                shed(response);
                return;
            }
        } else if (isWrite(request.getMethod()) && !redisReachable()) {
            shed(response);
            return;
        }
        if (jwt != null && tokenProvider.validateToken(jwt)) {
            String username = tokenProvider.getUsernameFromToken(jwt);
            List<SimpleGrantedAuthority> authorities = tokenProvider.extractRoles(jwt).stream()
                    .map(SimpleGrantedAuthority::new)
                    .toList();
            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(username, null, authorities);
            SecurityContextHolder.getContext().setAuthentication(authentication);
        } else {
            LOG.debug("Missing or invalid JWT for {}", request.getRequestURI());
        }
        filterChain.doFilter(request, response);
    }

    private void shed(HttpServletResponse response) throws IOException {
        if (dependencyTimeout != null) {
            dependencyTimeout.run();
        }
        response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
        response.setHeader("Retry-After", "1");
        response.setContentType("application/json");
        response.getWriter().write("{\"errorCode\":\"DEPENDENCY_TIMEOUT\"}");
    }

    private Boolean lookup(String jwt) {
        try (RedisConnection connection = redisConnectionFactory.getConnection()) {
            return connection.stringCommands().get(ServiceRevocation.redisKey(jwt)) != null;
        } catch (RuntimeException ex) {
            LOG.warn("Redis is unavailable for revocation check: {}", ex.toString());
            return null;
        }
    }

    private boolean redisReachable() {
        if (redisConnectionFactory == null) {
            return true;
        }
        try (RedisConnection connection = redisConnectionFactory.getConnection()) {
            String pong = connection.ping();
            return pong != null && pong.equalsIgnoreCase("PONG");
        } catch (RuntimeException ex) {
            LOG.warn("Redis is unavailable for revocation check: {}", ex.toString());
            return false;
        }
    }

    private static boolean isWrite(String method) {
        return "POST".equalsIgnoreCase(method)
                || "PUT".equalsIgnoreCase(method)
                || "PATCH".equalsIgnoreCase(method)
                || "DELETE".equalsIgnoreCase(method);
    }

    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
