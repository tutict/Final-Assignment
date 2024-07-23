package finalassignmentbackend.controller;


import finalassignmentbackend.entity.PermissionManagement;
import finalassignmentbackend.service.PermissionManagementService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;

@Path("/eventbus/permissions")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class PermissionManagementController {

    @Inject
    PermissionManagementService permissionManagementService;

    @POST
    public Response createPermission(PermissionManagement permission) {
        permissionManagementService.createPermission(permission);
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{permissionId}")
    public Response getPermissionById(@PathParam("permissionId") int permissionId) {
        PermissionManagement permission = permissionManagementService.getPermissionById(permissionId);
        if (permission != null) {
            return Response.ok(permission).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    public Response getAllPermissions() {
        List<PermissionManagement> permissions = permissionManagementService.getAllPermissions();
        return Response.ok(permissions).build();
    }

    @GET
    @Path("/name/{permissionName}")
    public Response getPermissionByName(@PathParam("permissionName") String permissionName) {
        PermissionManagement permission = permissionManagementService.getPermissionByName(permissionName);
        if (permission != null) {
            return Response.ok(permission).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/search")
    public Response getPermissionsByNameLike(@QueryParam("name") String permissionName) {
        List<PermissionManagement> permissions = permissionManagementService.getPermissionsByNameLike(permissionName);
        return Response.ok(permissions).build();
    }

    @PUT
    @Path("/{permissionId}")
    public Response updatePermission(@PathParam("permissionId") int permissionId, PermissionManagement updatedPermission) {
        PermissionManagement existingPermission = permissionManagementService.getPermissionById(permissionId);
        if (existingPermission != null) {
            updatedPermission.setPermissionId(permissionId);
            permissionManagementService.updatePermission(updatedPermission);
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{permissionId}")
    public Response deletePermission(@PathParam("permissionId") int permissionId) {
        permissionManagementService.deletePermission(permissionId);
        return Response.noContent().build();
    }

    @DELETE
    @Path("/name/{permissionName}")
    public Response deletePermissionByName(@PathParam("permissionName") String permissionName) {
        permissionManagementService.deletePermissionByName(permissionName);
        return Response.noContent().build();
    }
}