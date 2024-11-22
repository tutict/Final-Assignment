package finalassignmentbackend.controller;

import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.UserManagement;
import finalassignmentbackend.service.UserManagementService;
import jakarta.annotation.security.RolesAllowed;
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
import org.jboss.logging.Logger;

import java.util.List;

@Path("/eventbus/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class UserManagementController {

    private static final Logger logger = Logger.getLogger(UserManagementController.class);

    @Inject
    UserManagementService userManagementService;

    @POST
    @RolesAllowed("ADMIN")
    public Response createUser(UserManagement user) {
        logger.infof("Attempting to create user: %s", user.getUsername());
        if (userManagementService.isUsernameExists(user.getUsername())) {
            logger.warnf("Username already exists: %s", user.getUsername());
            return Response.status(Response.Status.CONFLICT).build();
        }
        userManagementService.createUser(user);
        logger.infof("User created successfully: %s", user.getUsername());
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
    public Response getCurrentUser(@Context SecurityContext securityContext) {
        String username = securityContext.getUserPrincipal().getName();
        logger.infof("Fetching current user by username: %s", username);
        UserManagement existingUser = userManagementService.getUserByUsername(username);
        if (existingUser != null) {
            logger.infof("User found: %s", username);
            return Response.ok(existingUser).build();
        } else {
            logger.warnf("User not found: %s", username);
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
    public Response updateCurrentUser(@Context SecurityContext securityContext, UserManagement updatedUser) {
        String username = securityContext.getUserPrincipal().getName();
        logger.infof("Attempting to update current user: %s", username);
        UserManagement existingUser = userManagementService.getUserByUsername(username);
        if (existingUser != null) {
            updatedUser.setUserId(existingUser.getUserId());
            UserManagement updatedUserResult = userManagementService.updateUser(updatedUser);
            logger.infof("User updated successfully: %s", username);
            return Response.ok(updatedUserResult).build();
        } else {
            logger.warnf("User not found: %s", username);
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @RolesAllowed("ADMIN")
    public Response getAllUsers() {
        logger.info("Fetching all users");
        List<UserManagement> users = userManagementService.getAllUsers();
        logger.infof("Total users found: %d", users.size());
        return Response.ok(users).build();
    }

    @GET
    @Path("/{userId}")
    @RolesAllowed({"USER", "ADMIN"})
    public Response getUserById(@PathParam("userId") int userId) {
        logger.infof("Fetching user by ID: %d", userId);
        UserManagement user = userManagementService.getUserById(userId);
        if (user != null) {
            logger.infof("User found: %d", userId);
            return Response.ok(user).build();
        } else {
            logger.warnf("User not found: %d", userId);
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/username/{username}")
    @RolesAllowed({"USER", "ADMIN"})
    public Response getUserByUsername(@PathParam("username") String username) {
        logger.infof("Fetching user by username: %s", username);
        UserManagement user = userManagementService.getUserByUsername(username);
        if (user != null) {
            logger.infof("User found: %s", username);
            return Response.ok(user).build();
        } else {
            logger.warnf("User not found: %s", username);
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/type/{userType}")
    @RolesAllowed("ADMIN")
    public Response getUsersByType(@PathParam("userType") String userType) {
        logger.infof("Fetching users by type: %s", userType);
        List<UserManagement> users = userManagementService.getUsersByType(userType);
        logger.infof("Total users of type %s: %d", userType, users.size());
        return Response.ok(users).build();
    }

    @GET
    @Path("/status/{status}")
    @RolesAllowed("ADMIN")
    public Response getUsersByStatus(@PathParam("status") String status) {
        logger.infof("Fetching users by status: %s", status);
        List<UserManagement> users = userManagementService.getUsersByStatus(status);
        logger.infof("Total users with status %s: %d", status, users.size());
        return Response.ok(users).build();
    }

    @PUT
    @Path("/{userId}")
    @RolesAllowed({"USER", "ADMIN"})
    public Response updateUser(@PathParam("userId") int userId, UserManagement updatedUser) {
        logger.infof("Attempting to update user: %d", userId);
        UserManagement existingUser = userManagementService.getUserById(userId);
        if (existingUser != null) {
            updatedUser.setUserId(userId);
            UserManagement updatedUserResult = userManagementService.updateUser(updatedUser);
            logger.infof("User updated successfully: %d", userId);
            return Response.ok(updatedUserResult).build();
        } else {
            logger.warnf("User not found: %d", userId);
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{userId}")
    @RolesAllowed("ADMIN")
    public Response deleteUser(@PathParam("userId") int userId) {
        logger.infof("Attempting to delete user: %d", userId);
        try {
            UserManagement userToDelete = userManagementService.getUserById(userId);
            if (userToDelete != null) {
                userManagementService.deleteUser(userId);
                logger.infof("User deleted successfully: %d", userId);
            } else {
                logger.warnf("User not found: %d", userId);
                return Response.status(Response.Status.NOT_FOUND).build();
            }
        } catch (Exception e) {
            logger.errorf("Error occurred while deleting user: %d", userId, e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
        return Response.noContent().build();
    }

    @DELETE
    @Path("/username/{username}")
    @RolesAllowed("ADMIN")
    public Response deleteUserByUsername(@PathParam("username") String username) {
        logger.infof("Attempting to delete user by username: %s", username);
        try {
            UserManagement userToDelete = userManagementService.getUserByUsername(username);
            if (userToDelete != null) {
                userManagementService.deleteUserByUsername(username);
                logger.infof("User deleted successfully: %s", username);
            } else {
                logger.warnf("User not found: %s", username);
                return Response.status(Response.Status.NOT_FOUND).build();
            }
        } catch (Exception e) {
            logger.errorf("Error occurred while deleting user by username: %s", username, e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
        return Response.noContent().build();
    }
}
