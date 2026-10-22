package finalassignmentbackend.controller;

import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.service.system.SysRequestHistoryService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/progress")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Progress Tracker", description = "Idempotent request progress endpoints")
@RolesAllowed({"SUPER_ADMIN", "ADMIN"})
public class ProgressItemController {

    private static final Logger LOG = Logger.getLogger(ProgressItemController.class.getName());

    @Inject
    SysRequestHistoryService sysRequestHistoryService;

    @POST
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "USER"})
    @RunOnVirtualThread
    public Response create(SysRequestHistory request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey,
                           @Context SecurityContext securityContext) {
        try {
            // 普通用户强制归属自己；管理员未显式指定负责人时也记为当前登录人，
            // 与单体/Go 后端的归属语义保持一致，避免同一张表出现“未记录”行。
            if (isRegularUser(securityContext) || request.getUserId() == null) {
                request.setUserId(sysRequestHistoryService.resolveUserId(securityContext.getUserPrincipal().getName()));
            }
            if (hasKey(idempotencyKey)) {
                if (sysRequestHistoryService.findByIdempotencyKey(idempotencyKey).isPresent()) {
                    return Response.status(208).build();
                }
                request.setIdempotencyKey(idempotencyKey);
            }
            SysRequestHistory saved = sysRequestHistoryService.createSysRequestHistory(request);
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Create request history failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{historyId}")
    @RunOnVirtualThread
    public Response update(@PathParam("historyId") Long historyId,
                           SysRequestHistory request) {
        try {
            request.setId(historyId);
            SysRequestHistory updated = sysRequestHistoryService.updateSysRequestHistory(request);
            return Response.ok(updated).build();
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Update request history failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{historyId}")
    @RunOnVirtualThread
    public Response delete(@PathParam("historyId") Long historyId) {
        try {
            sysRequestHistoryService.deleteSysRequestHistory(historyId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete request history failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{historyId}")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "USER"})
    @RunOnVirtualThread
    public Response get(@PathParam("historyId") Long historyId, @Context SecurityContext securityContext) {
        try {
            SysRequestHistory history = sysRequestHistoryService.findById(historyId);
            if (history == null) {
                return Response.status(Response.Status.NOT_FOUND).build();
            }
            if (isRegularUser(securityContext)
                    && !sysRequestHistoryService.isOwnedBy(historyId, securityContext.getUserPrincipal().getName())) {
                return Response.status(Response.Status.FORBIDDEN).build();
            }
            return Response.ok(history).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get request history failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "USER"})
    @RunOnVirtualThread
    public Response list(@Context SecurityContext securityContext) {
        try {
            List<SysRequestHistory> items = isRegularUser(securityContext)
                    ? sysRequestHistoryService.findByUsername(securityContext.getUserPrincipal().getName())
                    : sysRequestHistoryService.findAll();
            return Response.ok(items).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List request histories failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/status")
    @RunOnVirtualThread
    public Response listByStatus(@QueryParam("status") String status,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(sysRequestHistoryService.findByBusinessStatus(status, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List request histories by status failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/idempotency/{key}")
    @RunOnVirtualThread
    public Response getByIdempotencyKey(@PathParam("key") String key) {
        try {
            Optional<SysRequestHistory> history = sysRequestHistoryService.findByIdempotencyKey(key);
            return history.map(Response::ok)
                    .orElseGet(() -> Response.status(Response.Status.NOT_FOUND))
                    .build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get request history by idempotency key failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/status/{status}")
    @Deprecated
    public Response getByStatusDeprecated(@PathParam("status") String status) {
        return Response.status(Response.Status.GONE)
                .entity(Map.of("code", "GONE", "message", "此接口已废弃，请使用 /api/progress/status?status={status}"))
                .build();
    }

    @GET
    @Path("/timeRange")
    @RunOnVirtualThread
    public Response getByTimeRange(@QueryParam("startTime") String startTime,
                                   @QueryParam("endTime") String endTime,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(sysRequestHistoryService.searchByCreatedAtRange(startTime, endTime, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List request histories by time range failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    private boolean hasKey(String value) {
        return value != null && !value.isBlank();
    }

    private boolean isRegularUser(SecurityContext securityContext) {
        if (securityContext == null || securityContext.getUserPrincipal() == null) {
            return false;
        }
        boolean elevated = securityContext.isUserInRole("SUPER_ADMIN") || securityContext.isUserInRole("ADMIN");
        return !elevated && securityContext.isUserInRole("USER");
    }

    private Response.Status resolveStatus(Exception ex) {
        return (ex instanceof IllegalArgumentException || ex instanceof IllegalStateException)
                ? Response.Status.BAD_REQUEST
                : Response.Status.INTERNAL_SERVER_ERROR;
    }
}
