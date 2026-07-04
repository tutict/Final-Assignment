package finalassignmentbackend.controller;

import finalassignmentbackend.dto.RefreshRequest;
import finalassignmentbackend.dto.TokenResponse;
import finalassignmentbackend.dto.UserProfileResponse;
import finalassignmentbackend.dto.UserResponse;
import finalassignmentbackend.service.AuthWsService;
import finalassignmentbackend.service.AuthWsService.LoginRequest;
import finalassignmentbackend.service.AuthWsService.RegisterRequest;
import io.quarkus.security.Authenticated;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.annotation.security.PermitAll;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/auth")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Authentication", description = "Authentication endpoints for login and registration")
public class AuthController {

    private static final Logger LOG = Logger.getLogger(AuthController.class.getName());

    @Inject
    AuthWsService authWsService;

    @POST
    @Path("/login")
    @PermitAll
    @RunOnVirtualThread
    public Response login(LoginRequest loginRequest) {
        if (loginRequest == null || loginRequest.getUsername() == null || loginRequest.getPassword() == null) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(Map.of("error", "Username and password are required"))
                    .build();
        }
        try {
            Map<String, Object> result = authWsService.login(loginRequest);
            return Response.ok(result).build();
        } catch (Exception e) {
            LOG.log(Level.WARNING, "Login failed: {0}", e.getMessage());
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity(Map.of("error", e.getMessage()))
                    .build();
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
            return Response.status(Response.Status.CREATED)
                    .entity(Map.of("status", res))
                    .build();
        } catch (IllegalArgumentException e) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(Map.of("error", e.getMessage()))
                    .build();
        } catch (Exception e) {
            LOG.log(Level.WARNING, "Register failed: {0}", e.getMessage());
            return Response.status(Response.Status.CONFLICT)
                    .entity(Map.of("error", e.getMessage()))
                    .build();
        }
    }

    @GET
    @Path("/users")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN"})
    @RunOnVirtualThread
    public Response getAllUsers() {
        try {
            List<UserResponse> users = authWsService.getAllUsers();
            return Response.ok(users).build();
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "GetAllUsers failed: {0}", e.getMessage());
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(Map.of("error", e.getMessage()))
                    .build();
        }
    }

    @POST
    @Path("/refresh")
    @PermitAll
    @RunOnVirtualThread
    public Response refresh(RefreshRequest request) {
        try {
            TokenResponse token = authWsService.refresh(request);
            return Response.ok(token).build();
        } catch (Exception e) {
            LOG.log(Level.WARNING, "Refresh failed: {0}", e.getMessage());
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity(Map.of("error", e.getMessage()))
                    .build();
        }
    }

    @POST
    @Path("/logout")
    @Authenticated
    @RunOnVirtualThread
    public Response logout(@Context SecurityContext securityContext,
                           @HeaderParam("Authorization") String authorization) {
        try {
            String username = securityContext.getUserPrincipal() != null
                    ? securityContext.getUserPrincipal().getName()
                    : null;
            authWsService.logout(username, authorization);
            return Response.ok(Map.of("status", "LOGGED_OUT")).build();
        } catch (Exception e) {
            LOG.log(Level.WARNING, "Logout failed: {0}", e.getMessage());
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity(Map.of("error", e.getMessage()))
                    .build();
        }
    }

    @GET
    @Path("/me")
    @Authenticated
    @RunOnVirtualThread
    public Response getCurrentUser(@Context SecurityContext securityContext) {
        try {
            String username = securityContext.getUserPrincipal() != null
                    ? securityContext.getUserPrincipal().getName()
                    : null;
            UserProfileResponse profile = authWsService.getCurrentUserProfile(username);
            return Response.ok(profile).build();
        } catch (Exception e) {
            LOG.log(Level.WARNING, "GetCurrentUser failed: {0}", e.getMessage());
            return Response.status(Response.Status.NOT_FOUND)
                    .entity(Map.of("error", e.getMessage()))
                    .build();
        }
    }
}
