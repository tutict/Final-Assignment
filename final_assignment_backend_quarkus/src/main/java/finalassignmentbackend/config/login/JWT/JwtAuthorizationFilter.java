package finalassignmentbackend.config.login.JWT;

import io.quarkus.security.identity.SecurityIdentity;
import jakarta.ws.rs.core.SecurityContext;
import java.security.Principal;

public class JwtAuthorizationFilter implements SecurityContext {

    private final Authentication authentication;

    public JwtAuthorizationFilter(Authentication authentication) {
        this.authentication = authentication;
    }

    @Override
    public Principal getUserPrincipal() {
        return authentication;
    }

    @Override
    public boolean isUserInRole(String role) {
        return authentication.getAuthorities().stream()
                .anyMatch(grantedAuthority -> grantedAuthority.getAuthority().equals(role));
    }

    @Override
    public boolean isSecure() {
        return true;
    }

    @Override
    public String getAuthenticationScheme() {
        return "Bearer";
    }
}
