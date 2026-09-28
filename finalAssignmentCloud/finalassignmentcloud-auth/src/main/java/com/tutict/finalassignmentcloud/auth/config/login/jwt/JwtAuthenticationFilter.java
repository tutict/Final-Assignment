package com.tutict.finalassignmentcloud.auth.config.login.jwt;

import com.tutict.finalassignmentcloud.auth.reliability.BlacklistAccessPolicy;
import com.tutict.finalassignmentcloud.auth.service.TokenBlacklistService;
import org.jetbrains.annotations.NotNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger logger = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    private final TokenProvider tokenProvider;
    private final TokenBlacklistService tokenBlacklistService;

    public JwtAuthenticationFilter(TokenProvider tokenProvider) {
        this(tokenProvider, null);
    }

    private final Runnable dependencyTimeout;

    public JwtAuthenticationFilter(TokenProvider tokenProvider, TokenBlacklistService tokenBlacklistService) {
        this(tokenProvider, tokenBlacklistService, null);
    }

    public JwtAuthenticationFilter(TokenProvider tokenProvider,
                                   TokenBlacklistService tokenBlacklistService,
                                   Runnable dependencyTimeout) {
        this.tokenProvider = tokenProvider;
        this.tokenBlacklistService = tokenBlacklistService;
        this.dependencyTimeout = dependencyTimeout;
    }

    @Override
    protected void doFilterInternal(@NotNull HttpServletRequest request, @NotNull HttpServletResponse response, @NotNull FilterChain filterChain)
            throws ServletException, IOException {
        String jwt = getJwtFromRequest(request);
        logger.debug("Bearer token present: {}", jwt != null);

        if (jwt != null && tokenBlacklistService != null) {
            BlacklistAccessPolicy.Effect effect = BlacklistAccessPolicy.decide(
                    request.getMethod(), request.getRequestURI(), tokenBlacklistService.inspect(jwt));
            if (effect == BlacklistAccessPolicy.Effect.DENY) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType("application/json");
                response.getWriter().write("{\"errorCode\":\"UNAUTHORIZED\",\"message\":\"Token has expired, please login again\"}");
                return;
            }
            if (effect == BlacklistAccessPolicy.Effect.SHED) {
                if (dependencyTimeout != null) {
                    dependencyTimeout.run();
                }
                response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
                response.setHeader("Retry-After", "1");
                response.setContentType("application/json");
                response.getWriter().write("{\"errorCode\":\"DEPENDENCY_TIMEOUT\"}");
                return;
            }
        }

        if (jwt != null && tokenProvider.validateToken(jwt)) {
            String username = tokenProvider.getUsernameFromToken(jwt);
            List<String> roles = tokenProvider.extractRoles(jwt);
            logger.debug("JWT validated. Username: {}, Roles: {}", username, roles);

            List<SimpleGrantedAuthority> authorities = roles.stream()
                    .map(SimpleGrantedAuthority::new)
                    .collect(Collectors.toList());
            logger.debug("Authorities set: {}", authorities);

            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(username, null, authorities);
            SecurityContextHolder.getContext().setAuthentication(authentication);
            logger.debug("Authentication set for user: {}", username);
        } else {
            logger.warn("Invalid, revoked or missing JWT in request: {}", request.getRequestURI());
        }

        filterChain.doFilter(request, response);
    }

    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}

