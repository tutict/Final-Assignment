package finalassignmentbackend.config.login;

import io.quarkus.security.identity.SecurityIdentity;
import io.quarkus.security.runtime.QuarkusSecurityIdentity;
import io.smallrye.jwt.auth.principal.DefaultJWTCallerPrincipal;
import io.smallrye.jwt.auth.principal.JWTParser;
import io.vertx.ext.web.RoutingContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.inject.Inject;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.Set;

@ApplicationScoped
public class SecurityConfig {

    @Inject
    JWTParser jwtParser;

    @ConfigProperty(name = "jwt.secret-key")
    String secretKey;

    // Validate the token and extract SecurityIdentity
    public SecurityIdentity getSecurityIdentity(String token) {
        try {
            DefaultJWTCallerPrincipal callerPrincipal = (DefaultJWTCallerPrincipal) jwtParser.verify(token);
            Set<String> roles = callerPrincipal.getGroups();
            return QuarkusSecurityIdentity.builder()
                    .setPrincipal(callerPrincipal)
                    .addRoles(roles)
                    .build();
        } catch (Exception e) {
            return null;
        }
    }

    // Create a JWT token (simplified for demo purposes)
    public String createToken(String username, Set<String> roles) {
        // Implement token creation logic using your JWT library
        // Return a JWT string
        return "your.jwt.token";
    }

    // Filter that will intercept requests and check the JWT token
    @Provider
    @javax.annotation.Priority(Priorities.AUTHENTICATION)
    public static class JWTFilter implements ContainerRequestFilter {

        @Inject
        SecurityConfig securityConfig;

        @Override
        public void filter(ContainerRequestContext requestContext) {
            String token = extractToken(requestContext);
            if (token != null) {
                SecurityIdentity securityIdentity = securityConfig.getSecurityIdentity(token);
                if (securityIdentity != null) {
                    // Set the security identity for the current request
                    QuarkusSecurityIdentity.setCurrent(securityIdentity);
                    return;
                }
            }
            // If token is invalid or absent, abort the request with 401 Unauthorized
            requestContext.abortWith(Response.status(Response.Status.UNAUTHORIZED).build());
        }

        private String extractToken(ContainerRequestContext requestContext) {
            String authHeader = requestContext.getHeaderString(HttpHeaders.AUTHORIZATION);
            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                return authHeader.substring(7);
            }
            return null;
        }
    }

    // Handle successful authentication and allow access to routes
    public void onStartup(@Observes RoutingContext routingContext) {
        routingContext.addHeadersEndHandler(v -> {
            // Custom logic can be added here, e.g., logging, metrics, etc.
        });
    }
}
