package finalassignmentbackend.config.login.jwt;

import finalassignmentbackend.service.TokenBlacklistService;
import io.quarkus.security.identity.SecurityIdentity;
import io.quarkus.security.runtime.QuarkusPrincipal;
import io.quarkus.security.runtime.QuarkusSecurityIdentity;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;

import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Provider
@Priority(Priorities.AUTHENTICATION)
public class JwtAuthenticationFilter implements ContainerRequestFilter {

    private static final Logger logger = Logger.getLogger(JwtAuthenticationFilter.class.getName());

    @Inject
    TokenProvider tokenProvider;

    @Inject
    TokenBlacklistService tokenBlacklistService;

    @Override
    public void filter(ContainerRequestContext requestContext) throws IOException {
        if (shouldSkip(requestContext)) {
            return;
        }

        String jwt = getJwtFromRequest(requestContext);
        if (jwt == null) {
            return;
        }

        if (tokenBlacklistService.isBlacklisted(jwt)) {
            logger.log(Level.WARNING, "Rejected blacklisted JWT for request {0}", requestContext.getUriInfo().getRequestUri());
            requestContext.abortWith(Response.status(Response.Status.UNAUTHORIZED)
                    .entity("{\"error\":\"Token has expired, please login again\"}")
                    .build());
            return;
        }

        if (!tokenProvider.validateToken(jwt)) {
            logger.log(Level.WARNING, "Invalid JWT for request {0}", requestContext.getUriInfo().getRequestUri());
            return;
        }

        String username = tokenProvider.getUsernameFromToken(jwt);
        List<String> roles = tokenProvider.extractRoles(jwt);
        Set<String> authorities = roles.stream().collect(Collectors.toSet());
        SecurityIdentity identity = QuarkusSecurityIdentity.builder()
                .setPrincipal(new QuarkusPrincipal(username))
                .addRoles(authorities)
                .build();
        requestContext.setSecurityContext(new SecurityContextImpl(identity));
    }

    private boolean shouldSkip(ContainerRequestContext requestContext) {
        String path = requestContext.getUriInfo().getPath();
        return path.startsWith("api/auth/login")
                || path.startsWith("api/auth/register")
                || path.startsWith("api/auth/refresh");
    }

    private String getJwtFromRequest(ContainerRequestContext requestContext) {
        String bearerToken = requestContext.getHeaderString(HttpHeaders.AUTHORIZATION);
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }

    private static class SecurityContextImpl implements jakarta.ws.rs.core.SecurityContext {
        private final SecurityIdentity identity;

        SecurityContextImpl(SecurityIdentity identity) {
            this.identity = identity;
        }

        @Override
        public java.security.Principal getUserPrincipal() {
            return identity.getPrincipal();
        }

        @Override
        public boolean isUserInRole(String role) {
            return identity.getRoles().contains(normalizeRole(role));
        }

        @Override
        public boolean isSecure() {
            return false;
        }

        @Override
        public String getAuthenticationScheme() {
            return "Bearer";
        }

        private String normalizeRole(String role) {
            if (role == null) {
                return "";
            }
            String normalized = role.trim().toUpperCase();
            return normalized.startsWith("ROLE_") ? normalized.substring("ROLE_".length()) : normalized;
        }
    }
}