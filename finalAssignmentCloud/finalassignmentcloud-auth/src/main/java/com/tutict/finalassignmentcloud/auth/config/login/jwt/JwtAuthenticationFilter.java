package com.tutict.finalassignmentcloud.auth.config.login.jwt;

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

    public JwtAuthenticationFilter(TokenProvider tokenProvider, TokenBlacklistService tokenBlacklistService) {
        this.tokenProvider = tokenProvider;
        this.tokenBlacklistService = tokenBlacklistService;
    }

    @Override
    protected void doFilterInternal(@NotNull HttpServletRequest request, @NotNull HttpServletResponse response, @NotNull FilterChain filterChain)
            throws ServletException, IOException {
        String jwt = getJwtFromRequest(request);
        logger.debug("Bearer token present: {}", jwt != null);

        if (jwt != null && isNotRevoked(jwt) && tokenProvider.validateToken(jwt)) {
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

    private boolean isNotRevoked(String jwt) {
        if (tokenBlacklistService == null) {
            return true;
        }
        return !tokenBlacklistService.isBlacklisted(jwt);
    }

    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}

