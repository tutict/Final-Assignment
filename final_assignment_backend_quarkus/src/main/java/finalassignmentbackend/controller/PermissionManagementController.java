package finalassignmentbackend.controller;

import finalassignmentbackend.entity.PermissionManagement;
import finalassignmentbackend.service.PermissionManagementService;
import io.smallrye.common.annotation.RunOnVirtualThread;
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
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;

@Path("/api/permissions")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Permission Management", description = "Permission Management Controller for managing permissions")
public class PermissionManagementController {

    @Inject
    PermissionManagementService permissionManagementService;

    @POST
    @RunOnVirtualThread
    public Response createPermission(PermissionManagement permission, @QueryParam("idempotencyKey") String idempotencyKey) {
        permissionManagementService.checkAndInsertIdempotency(idempotencyKey, permission, "create");
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{permissionId}")
    @RunOnVirtualThread
    public Response getPermissionById(@PathParam("permissionId") int permissionId) {
        PermissionManagement permission = permissionManagementService.getPermissionById(permissionId);
        if (permission != null) {
            return Response.ok(permission).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response getAllPermissions() {
        List<PermissionManagement> permissions = permissionManagementService.getAllPermissions();
        return Response.ok(permissions).build();
    }

    @GET
    @Path("/name/{permissionName}")
    @RunOnVirtualThread
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
    @RunOnVirtualThread
    public Response getPermissionsByNameLike(@QueryParam("name") String permissionName) {
        List<PermissionManagement> permissions = permissionManagementService.getPermissionsByNameLike(permissionName);
        return Response.ok(permissions).build();
    }

    @PUT
    @Path("/{permissionId}")
    @RunOnVirtualThread
    public Response updatePermission(@PathParam("permissionId") int permissionId, PermissionManagement updatedPermission, @QueryParam("idempotencyKey") String idempotencyKey) {
        PermissionManagement existingPermission = permissionManagementService.getPermissionById(permissionId);
        if (existingPermission != null) {
            updatedPermission.setPermissionId(permissionId);
            permissionManagementService.checkAndInsertIdempotency(idempotencyKey, updatedPermission, "update");
            return Response.ok(Response.Status.OK).entity(updatedPermission).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{permissionId}")
    @RunOnVirtualThread
    public Response deletePermission(@PathParam("permissionId") int permissionId) {
        permissionManagementService.deletePermission(permissionId);
        return Response.noContent().build();
    }

    @DELETE
    @Path("/name/{permissionName}")
    @RunOnVirtualThread
    public Response deletePermissionByName(@PathParam("permissionName") String permissionName) {
        permissionManagementService.deletePermissionByName(permissionName);
        return Response.noContent().build();
    }
}
