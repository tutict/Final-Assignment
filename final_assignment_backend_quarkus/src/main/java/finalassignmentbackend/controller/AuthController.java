package finalassignmentbackend.controller;

import finalassignmentbackend.service.AuthWsService;
import finalassignmentbackend.service.AuthWsService.LoginRequest;
import finalassignmentbackend.service.AuthWsService.RegisterRequest;
import finalassignmentbackend.entity.UserManagement;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.annotation.security.PermitAll;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

@Path("/api/auth")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Authentication", description = "Authentication Controller for user authentication and registration")
public class AuthController {

    private static final Logger logger = Logger.getLogger(AuthController.class.getName());

    @Inject
    AuthWsService authWsService;

    @POST
    @Path("/login")
    @PermitAll
    @RunOnVirtualThread
    public Response login(LoginRequest loginRequest) {
        try {
            Map<String, Object> result = authWsService.login(loginRequest);
            if (result.containsKey("jwtToken")) {
                return Response.ok(result).build();
            } else {
                return Response.status(Response.Status.UNAUTHORIZED).entity(result).build();
            }
        } catch (Exception e) {
            logger.warning("Login failed: " + e.getMessage());
            return Response.status(Response.Status.UNAUTHORIZED).entity(Map.of("error", e.getMessage())).build();
        }
    }

    @POST
    @Path("/register")
    @PermitAll
    @RunOnVirtualThread
    @Transactional
    public Response registerUser(RegisterRequest registerRequest) {
        try {
            String res = authWsService.registerUser(registerRequest);
            return Response.status(Response.Status.CREATED).entity(Map.of("status", res)).build();
        } catch (Exception e) {
            logger.warning("Register failed: " + e.getMessage());
            return Response.status(Response.Status.CONFLICT).entity(Map.of("error", e.getMessage())).build();
        }
    }

    @GET
    @Path("/users")
    @RolesAllowed("ADMIN")
    @RunOnVirtualThread
    public Response getAllUsers() {
        try {
            List<UserManagement> users = authWsService.getAllUsers();
            return Response.ok(users).build();
        } catch (Exception e) {
            logger.warning("GetAllUsers failed: " + e.getMessage());
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).entity(Map.of("error", e.getMessage())).build();
        }
    }
}
