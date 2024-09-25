package finalassignmentbackend.config.login.JWT;

import finalassignmentbackend.entity.UserManagement;
import finalassignmentbackend.service.UserManagementService;
import io.quarkus.security.AuthenticationFailedException;
import io.quarkus.security.UnauthorizedException;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.inject.Inject;
import jakarta.ws.rs.FormParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;


@Path("/api/auth")
public class AuthController {

    private static final Logger LOGGER = Logger.getLogger(AuthController.class);

    @Inject
    TokenProvider tokenProvider;

    @Inject
    SecurityIdentity securityIdentity;
    @Inject
    UserManagementService userManagementService;

    @POST
    @Path("/login")
    public Response login(@FormParam("username") String username, @FormParam("password") String password) {
        try {
            if (!authenticate(username, password)) {
                throw new UnauthorizedException();
            }

            String authorities = String.join(",", securityIdentity.getRoles());

            String token = tokenProvider.createToken(username, authorities);

            return Response.ok().entity("Bearer " + token).build();
        } catch (UnauthorizedException | AuthenticationFailedException e) {
            return Response.status(Response.Status.UNAUTHORIZED).entity("Unauthorized").build();
        }
    }

    private boolean authenticate(String username, String password) {
        UserManagement user = userManagementService.getAllUsers(username, password);
    }
}
