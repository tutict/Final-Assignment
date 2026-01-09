package finalassignmentbackend.controller;

import finalassignmentbackend.entity.SysPermission;
import finalassignmentbackend.service.SysPermissionService;
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

import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/permissions")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Permission Management", description = "System permission management")
public class PermissionManagementController {

    private static final Logger LOG = Logger.getLogger(PermissionManagementController.class.getName());

    @Inject
    SysPermissionService sysPermissionService;

    @POST
    @RunOnVirtualThread
    public Response create(SysPermission request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (sysPermissionService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                sysPermissionService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            SysPermission saved = sysPermissionService.createSysPermission(request);
            if (useKey && saved.getPermissionId() != null) {
                sysPermissionService.markHistorySuccess(idempotencyKey, saved.getPermissionId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                sysPermissionService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create permission failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{permissionId}")
    @RunOnVirtualThread
    public Response update(@PathParam("permissionId") Integer permissionId,
                           SysPermission request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setPermissionId(permissionId);
            if (useKey) {
                sysPermissionService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            SysPermission updated = sysPermissionService.updateSysPermission(request);
            if (useKey && updated.getPermissionId() != null) {
                sysPermissionService.markHistorySuccess(idempotencyKey, updated.getPermissionId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                sysPermissionService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update permission failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{permissionId}")
    @RunOnVirtualThread
    public Response delete(@PathParam("permissionId") Integer permissionId) {
        try {
            sysPermissionService.deleteSysPermission(permissionId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete permission failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{permissionId}")
    @RunOnVirtualThread
    public Response get(@PathParam("permissionId") Integer permissionId) {
        try {
            SysPermission permission = sysPermissionService.findById(permissionId);
            return permission == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(permission).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get permission failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response list() {
        try {
            return Response.ok(sysPermissionService.findAll()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List permissions failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/parent/{parentId}")
    @RunOnVirtualThread
    public Response listByParent(@PathParam("parentId") Integer parentId,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 50 : size;
            return Response.ok(sysPermissionService.findByParentId(parentId, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List permissions by parent failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/code/prefix")
    @RunOnVirtualThread
    public Response searchByCodePrefix(@QueryParam("permissionCode") String permissionCode,
                                       @QueryParam("page") Integer page,
                                       @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysPermissionService.searchByPermissionCodePrefix(permissionCode, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/code/fuzzy")
    @RunOnVirtualThread
    public Response searchByCodeFuzzy(@QueryParam("permissionCode") String permissionCode,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysPermissionService.searchByPermissionCodeFuzzy(permissionCode, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/name/prefix")
    @RunOnVirtualThread
    public Response searchByNamePrefix(@QueryParam("permissionName") String permissionName,
                                       @QueryParam("page") Integer page,
                                       @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysPermissionService.searchByPermissionNamePrefix(permissionName, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/name/fuzzy")
    @RunOnVirtualThread
    public Response searchByNameFuzzy(@QueryParam("permissionName") String permissionName,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysPermissionService.searchByPermissionNameFuzzy(permissionName, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/type")
    @RunOnVirtualThread
    public Response searchByType(@QueryParam("permissionType") String permissionType,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysPermissionService.searchByPermissionType(permissionType, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/api-path")
    @RunOnVirtualThread
    public Response searchByApiPath(@QueryParam("apiPath") String apiPath,
                                    @QueryParam("page") Integer page,
                                    @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysPermissionService.searchByApiPathPrefix(apiPath, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/menu-path")
    @RunOnVirtualThread
    public Response searchByMenuPath(@QueryParam("menuPath") String menuPath,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysPermissionService.searchByMenuPathPrefix(menuPath, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/visible")
    @RunOnVirtualThread
    public Response searchByVisible(@QueryParam("isVisible") boolean isVisible,
                                    @QueryParam("page") Integer page,
                                    @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysPermissionService.searchByIsVisible(isVisible, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/external")
    @RunOnVirtualThread
    public Response searchByExternal(@QueryParam("isExternal") boolean isExternal,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysPermissionService.searchByIsExternal(isExternal, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/status")
    @RunOnVirtualThread
    public Response searchByStatus(@QueryParam("status") String status,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysPermissionService.searchByStatus(status, resolvedPage, resolvedSize)).build();
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
