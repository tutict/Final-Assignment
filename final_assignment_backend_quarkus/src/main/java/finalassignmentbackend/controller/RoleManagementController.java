package finalassignmentbackend.controller;

import finalassignmentbackend.entity.SysRole;
import finalassignmentbackend.entity.SysRolePermission;
import finalassignmentbackend.service.SysRolePermissionService;
import finalassignmentbackend.service.SysRoleService;
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
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/roles")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Role Management", description = "System role management")
public class RoleManagementController {

    private static final Logger LOG = Logger.getLogger(RoleManagementController.class.getName());

    @Inject
    SysRoleService sysRoleService;

    @Inject
    SysRolePermissionService sysRolePermissionService;

    @POST
    @RunOnVirtualThread
    public Response createRole(SysRole request,
                               @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (sysRoleService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                sysRoleService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            SysRole saved = sysRoleService.createSysRole(request);
            if (useKey && saved.getRoleId() != null) {
                sysRoleService.markHistorySuccess(idempotencyKey, saved.getRoleId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                sysRoleService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create role failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{roleId}")
    @RunOnVirtualThread
    public Response updateRole(@PathParam("roleId") Integer roleId,
                               SysRole request,
                               @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setRoleId(roleId);
            if (useKey) {
                sysRoleService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            SysRole updated = sysRoleService.updateSysRole(request);
            if (useKey && updated.getRoleId() != null) {
                sysRoleService.markHistorySuccess(idempotencyKey, updated.getRoleId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                sysRoleService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update role failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{roleId}")
    @RunOnVirtualThread
    public Response deleteRole(@PathParam("roleId") Integer roleId) {
        try {
            sysRoleService.deleteSysRole(roleId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete role failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{roleId}")
    @RunOnVirtualThread
    public Response getRole(@PathParam("roleId") Integer roleId) {
        try {
            SysRole role = sysRoleService.findById(roleId);
            return role == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(role).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get role failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response listRoles() {
        try {
            return Response.ok(sysRoleService.findAll()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List roles failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/by-code/{roleCode}")
    @RunOnVirtualThread
    public Response getByCode(@PathParam("roleCode") String roleCode) {
        try {
            SysRole role = sysRoleService.findByRoleCode(roleCode);
            return role == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(role).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get role by code failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/code/prefix")
    @RunOnVirtualThread
    public Response searchByCodePrefix(@QueryParam("roleCode") String roleCode,
                                       @QueryParam("page") Integer page,
                                       @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRoleService.searchByRoleCodePrefix(roleCode, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/code/fuzzy")
    @RunOnVirtualThread
    public Response searchByCodeFuzzy(@QueryParam("roleCode") String roleCode,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRoleService.searchByRoleCodeFuzzy(roleCode, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/name/prefix")
    @RunOnVirtualThread
    public Response searchByNamePrefix(@QueryParam("roleName") String roleName,
                                       @QueryParam("page") Integer page,
                                       @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRoleService.searchByRoleNamePrefix(roleName, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/name/fuzzy")
    @RunOnVirtualThread
    public Response searchByNameFuzzy(@QueryParam("roleName") String roleName,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRoleService.searchByRoleNameFuzzy(roleName, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/type")
    @RunOnVirtualThread
    public Response searchByRoleType(@QueryParam("roleType") String roleType,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRoleService.searchByRoleType(roleType, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/data-scope")
    @RunOnVirtualThread
    public Response searchByDataScope(@QueryParam("dataScope") String dataScope,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRoleService.searchByDataScope(dataScope, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/status")
    @RunOnVirtualThread
    public Response searchByStatus(@QueryParam("status") String status,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRoleService.searchByStatus(status, resolvedPage, resolvedSize)).build();
    }

    @POST
    @Path("/{roleId}/permissions")
    @RunOnVirtualThread
    public Response addPermission(@PathParam("roleId") Integer roleId,
                                  SysRolePermission relation,
                                  @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            relation.setRoleId(roleId);
            if (useKey) {
                if (sysRolePermissionService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                sysRolePermissionService.checkAndInsertIdempotency(idempotencyKey, relation, "create");
            }
            SysRolePermission saved = sysRolePermissionService.createRelation(relation);
            if (useKey && saved.getId() != null) {
                sysRolePermissionService.markHistorySuccess(idempotencyKey, saved.getId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                sysRolePermissionService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Add role permission failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/permissions/{relationId}")
    @RunOnVirtualThread
    public Response deletePermission(@PathParam("relationId") Long relationId) {
        try {
            sysRolePermissionService.deleteRelation(relationId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete role permission failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{roleId}/permissions")
    @RunOnVirtualThread
    public Response listPermissions(@PathParam("roleId") Integer roleId,
                                    @QueryParam("page") Integer page,
                                    @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 50 : size;
            return Response.ok(sysRolePermissionService.findByRoleId(roleId, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List role permissions failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/permissions/{relationId}")
    @RunOnVirtualThread
    public Response updatePermission(@PathParam("relationId") Long relationId,
                                     SysRolePermission relation,
                                     @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            relation.setId(relationId);
            if (useKey) {
                sysRolePermissionService.checkAndInsertIdempotency(idempotencyKey, relation, "update");
            }
            SysRolePermission updated = sysRolePermissionService.updateRelation(relation);
            if (useKey && updated.getId() != null) {
                sysRolePermissionService.markHistorySuccess(idempotencyKey, updated.getId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                sysRolePermissionService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update role permission failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/permissions/{relationId}")
    @RunOnVirtualThread
    public Response getPermissionRelation(@PathParam("relationId") Long relationId) {
        try {
            SysRolePermission relation = sysRolePermissionService.findById(relationId);
            return relation == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(relation).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get role permission failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/permissions")
    @RunOnVirtualThread
    public Response listAllRelations(@QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 50 : size;
            return Response.ok(sysRolePermissionService.findAll(resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List role permission relations failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/permissions/by-permission/{permissionId}")
    @RunOnVirtualThread
    public Response listByPermission(@PathParam("permissionId") Integer permissionId,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 50 : size;
            return Response.ok(sysRolePermissionService.findByPermissionId(permissionId, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List role permissions by permissionId failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/permissions/search")
    @RunOnVirtualThread
    public Response searchRolePermissionBindings(@QueryParam("roleId") Integer roleId,
                                                 @QueryParam("permissionId") Integer permissionId,
                                                 @QueryParam("page") Integer page,
                                                 @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysRolePermissionService.findByRoleIdAndPermissionId(roleId, permissionId, resolvedPage, resolvedSize)).build();
    }

    private boolean hasKey(String value) {
        return value != null && !value.isBlank();
    }

    private Response.Status resolveStatus(Exception ex) {
        return (ex instanceof IllegalArgumentException || ex instanceof IllegalStateException)
                ? Response.Status.BAD_REQUEST
                : Response.Status.INTERNAL_SERVER_ERROR;
    }
}
