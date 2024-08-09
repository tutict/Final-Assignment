package finalassignmentbackend.config.login.JWT;
import io.quarkus.security.AuthenticationFailedException;
import io.quarkus.security.UnauthorizedException;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.inject.Inject;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.FormParam;
import jakarta.ws.rs.core.Response;

import java.util.stream.Collectors;

@Path("/api/auth")
public class AuthController {

    @Inject
    TokenProvider tokenProvider;

    @Inject
    AuthenticationManager authenticationManager;

    @POST
    @Path("/login")
    public Response login(@FormParam("username") String username, @FormParam("password") String password) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(username, password)
            );

            if (!authentication.isAuthenticated()) {
                throw new AuthenticationFailedException();
            }

            String authorities = authentication.getAuthorities().stream()
                    .map(grantedAuthority -> grantedAuthority.getAuthority())
                    .collect(Collectors.joining(","));

            String token = tokenProvider.createToken(username, authorities);

            return Response.ok().entity("Bearer " + token).build();
        } catch (UnauthorizedException | AuthenticationFailedException e) {
            return Response.status(Response.Status.UNAUTHORIZED).entity("Unauthorized").build();
        }
    }
}
