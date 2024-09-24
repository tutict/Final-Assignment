package finalassignmentbackend.controller;


import finalassignmentbackend.entity.UserManagement;
import finalassignmentbackend.service.UserManagementService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;

@Path("/eventbus/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class UserManagementController {

    @Inject
    UserManagementService userManagementService;

    @POST
    public Response createUser(UserManagement user) {
        if (userManagementService.isUsernameExists(user.getUsername())) {
            return Response.status(Response.Status.CONFLICT).build();
        }
        userManagementService.createUser(user);
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{userId}")
    public Response getUserById(@PathParam("userId") int userId) {
        UserManagement user = userManagementService.getUserById(userId);
        if (user != null) {
            return Response.ok(user).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/username/{username}")
    public Response getUserByUsername(@PathParam("username") String username) {
        UserManagement user = userManagementService.getUserByUsername(username);
        if (user != null) {
            return Response.ok(user).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    public Response getAllUsers() {
        List<UserManagement> users = userManagementService.getAllUsers();
        return Response.ok(users).build();
    }

    @GET
    @Path("/type/{userType}")
    public Response getUsersByType(@PathParam("userType") String userType) {
        List<UserManagement> users = userManagementService.getUsersByType(userType);
        return Response.ok(users).build();
    }

    @GET
    @Path("/status/{status}")
    public Response getUsersByStatus(@PathParam("status") String status) {
        List<UserManagement> users = userManagementService.getUsersByStatus(status);
        return Response.ok(users).build();
    }

    @PUT
    @Path("/{userId}")
    public Response updateUser(@PathParam("userId") int userId, UserManagement updatedUser) {
        UserManagement existingUser = userManagementService.getUserById(userId);
        if (existingUser != null) {
            updatedUser.setUserId(userId);
            userManagementService.updateUser(updatedUser);
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{userId}")
    public Response deleteUser(@PathParam("userId") int userId) {
        userManagementService.deleteUser(userId);
        return Response.noContent().build();
    }

    @DELETE
    @Path("/username/{username}")
    public Response deleteUserByUsername(@PathParam("username") String username) {
        userManagementService.deleteUserByUsername(username);
        return Response.noContent().build();
    }
}