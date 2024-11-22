package finalassignmentbackend.controller;

import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.RoleManagement;
import finalassignmentbackend.service.RoleManagementService;
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

@Path("/eventbus/roles")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class RoleManagementController {

    @Inject
    RoleManagementService roleManagementService;

    @POST
    public Response createRole(RoleManagement role) {
        roleManagementService.createRole(role);
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{roleId}")
    public Response getRoleById(@PathParam("roleId") int roleId) {
        RoleManagement role = roleManagementService.getRoleById(roleId);
        if (role != null) {
            return Response.ok(role).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    public Response getAllRoles() {
        List<RoleManagement> roles = roleManagementService.getAllRoles();
        return Response.ok(roles).build();
    }

    @GET
    @Path("/name/{roleName}")
    public Response getRoleByName(@PathParam("roleName") String roleName) {
        RoleManagement role = roleManagementService.getRoleByName(roleName);
        if (role != null) {
            return Response.ok(role).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/search")
    public Response getRolesByNameLike(@QueryParam("name") String roleName) {
        List<RoleManagement> roles = roleManagementService.getRolesByNameLike(roleName);
        return Response.ok(roles).build();
    }

    @PUT
    @Path("/{roleId}")
    public Response updateRole(@PathParam("roleId") int roleId, RoleManagement updatedRole) {
        RoleManagement existingRole = roleManagementService.getRoleById(roleId);
        if (existingRole != null) {
            updatedRole.setRoleId(roleId);
            roleManagementService.updateRole(updatedRole);
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{roleId}")
    public Response deleteRole(@PathParam("roleId") int roleId) {
        roleManagementService.deleteRole(roleId);
        return Response.noContent().build();
    }

    @DELETE
    @Path("/name/{roleName}")
    public Response deleteRoleByName(@PathParam("roleName") String roleName) {
        roleManagementService.deleteRoleByName(roleName);
        return Response.noContent().build();
    }
}
