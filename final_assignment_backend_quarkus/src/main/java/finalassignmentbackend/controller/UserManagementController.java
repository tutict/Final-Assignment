package finalassignmentbackend.controller;

import finalassignmentbackend.entity.UserManagement;
import finalassignmentbackend.service.UserManagementService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "User Management", description = "User Management Controller for managing user accounts")
public class UserManagementController {

    private static final Logger logger = Logger.getLogger(String.valueOf(UserManagementController.class));

    @Inject
    UserManagementService userManagementService;

    @POST
    @RolesAllowed("ADMIN")
    @RunOnVirtualThread
    public Response createUser(UserManagement user, String idempotencyKey) {
        logger.info(String.format("Attempting to create user: %s", user.getUsername()));
        if (userManagementService.isUsernameExists(user.getUsername())) {
            logger.warning(String.format("Username already exists: %s", user.getUsername()));
            return Response.status(Response.Status.CONFLICT).build();
        }
        userManagementService.checkAndInsertIdempotency(idempotencyKey, user, "create");
        logger.info(String.format("User created successfully: %s", user.getUsername()));
        return Response.status(Response.Status.CREATED).build();
    }

    /**
     * 获取当前用户的违规详情
     *
     * @param securityContext 安全上下文，包含当前用户信息
     * @return 当前用户的违规详情或NotFound状态
     */
    @GET
    @Path("/me")
    @RolesAllowed({"USER", "ADMIN"})
    @RunOnVirtualThread
    public Response getCurrentUser(@Context SecurityContext securityContext) {
        String username = securityContext.getUserPrincipal().getName();
        logger.info(String.format("fetching current user by username: %s", username));
        UserManagement existingUser = userManagementService.getUserByUsername(username);
        if (existingUser != null) {
            logger.info(String.format("User found: %s", username));
            return Response.ok(existingUser).build();
        } else {
            logger.warning(String.format("User not found: %s", username));
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    /**
     * 更新当前用户信息
     *
     * @param securityContext 安全上下文，包含当前用户信息
     * @param updatedUser     更新后的用户信息
     * @return 更新结果响应
     */
    @PUT
    @Path("/me")
    @RolesAllowed({"USER", "ADMIN"})
    @RunOnVirtualThread
    public Response updateCurrentUser(@Context SecurityContext securityContext, UserManagement updatedUser, String idempotencyKey) {
        String username = securityContext.getUserPrincipal().getName();
        logger.info(String.format("Attempting to update current user: %s", username));
        UserManagement existingUser = userManagementService.getUserByUsername(username);
        if (existingUser != null) {
            updatedUser.setUserId(existingUser.getUserId());
            userManagementService.checkAndInsertIdempotency(idempotencyKey, updatedUser, "update");
            logger.info(String.format("User updated successfully: %s", username));
            return Response.ok().build();
        } else {
            logger.warning(String.format("User not found: %s", username));
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @RolesAllowed("ADMIN")
    @RunOnVirtualThread
    public Response getAllUsers() {
        logger.info("Fetching all users");
        List<UserManagement> users = userManagementService.getAllUsers();
        logger.info(String.format("Total users found: %d", users.size()));
        return Response.ok(users).build();
    }

    @GET
    @Path("/{userId}")
    @RolesAllowed({"USER", "ADMIN"})
    @RunOnVirtualThread
    public Response getUserById(@PathParam("userId") int userId) {
        logger.info(String.format("Fetching user by ID: %d", userId));
        UserManagement user = userManagementService.getUserById(userId);
        if (user != null) {
            logger.info(String.format("User found: %d", userId));
            return Response.ok(user).build();
        } else {
            logger.warning(String.format("User not found: %d", userId));
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/username/{username}")
    @RolesAllowed({"USER", "ADMIN"})
    @RunOnVirtualThread
    public Response getUserByUsername(@PathParam("username") String username) {
        logger.info(String.format("Fetching user by username: %s", username));
        UserManagement user = userManagementService.getUserByUsername(username);
        if (user != null) {
            logger.info(String.format("User found: %s", username));
            return Response.ok(user).build();
        } else {
            logger.warning(String.format("User not found: %s", username));
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/type/{userType}")
    @RolesAllowed("ADMIN")
    @RunOnVirtualThread
    public Response getUsersByType(@PathParam("userType") String userType) {
        logger.info(String.format("Fetching users by type: %s", userType));
        List<UserManagement> users = userManagementService.getUsersByType(userType);
        logger.info(String.format("Total users of type %s: %d", userType, users.size()));
        return Response.ok(users).build();
    }

    @GET
    @Path("/status/{status}")
    @RolesAllowed("ADMIN")
    @RunOnVirtualThread
    public Response getUsersByStatus(@PathParam("status") String status) {
        logger.info(String.format("Fetching users by status: %s", status));
        List<UserManagement> users = userManagementService.getUsersByStatus(status);
        logger.info(String.format("Total users with status %s: %d", status, users.size()));
        return Response.ok(users).build();
    }

    @PUT
    @Path("/{userId}")
    @RolesAllowed({"USER", "ADMIN"})
    @RunOnVirtualThread
    public Response updateUser(@PathParam("userId") int userId, UserManagement updatedUser, String idempotencyKey) {
        logger.info(String.format("Attempting to update user: %d", userId));
        UserManagement existingUser = userManagementService.getUserById(userId);
        if (existingUser != null) {
            updatedUser.setUserId(userId);
            userManagementService.checkAndInsertIdempotency(idempotencyKey, updatedUser, "update");
            logger.info(String.format("User updated successfully: %d", userId));
            return Response.status(Response.Status.OK).entity(updatedUser).build();
        } else {
            logger.warning(String.format("User not found: %d", userId));
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{userId}")
    @RolesAllowed("ADMIN")
    @RunOnVirtualThread
    public Response deleteUser(@PathParam("userId") int userId) {
        logger.info(String.format("Attempting to delete user: %d", userId));
        try {
            UserManagement userToDelete = userManagementService.getUserById(userId);
            if (userToDelete != null) {
                userManagementService.deleteUser(userId);
                logger.info(String.format("User deleted successfully: %d", userId));
            } else {
                logger.warning(String.format("User not found: %d", userId));
                return Response.status(Response.Status.NOT_FOUND).build();
            }
        } catch (Exception e) {
            logger.log(Level.SEVERE, "An error occurred while processing request for user {0}.", new Object[]{userId, e});
        }
        return Response.noContent().build();
    }

    @DELETE
    @Path("/username/{username}")
    @RolesAllowed("ADMIN")
    @RunOnVirtualThread
    public Response deleteUserByUsername(@PathParam("username") String username) {
        logger.info(String.format("Attempting to delete user by username: %s", username));
        try {
            UserManagement userToDelete = userManagementService.getUserByUsername(username);
            if (userToDelete != null) {
                userManagementService.deleteUserByUsername(username);
                logger.info(String.format("User deleted successfully: %s", username));
            } else {
                logger.warning(String.format("User not found: %s", username));
                return Response.status(Response.Status.NOT_FOUND).build();
            }
        } catch (Exception e) {
            logger.log(Level.SEVERE, "An error occurred while processing request for user {0}.", new Object[]{username, e});
        }
        return Response.noContent().build();
    }
}
