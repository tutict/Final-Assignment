package finalassignmentbackend.controller;

import finalassignmentbackend.entity.AuditLoginLog;
import finalassignmentbackend.service.AuditLoginLogService;
import io.smallrye.common.annotation.RunOnVirtualThread;
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
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/logs/login")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Login Audit", description = "Login audit log management")
public class LoginLogController {

    private static final Logger LOG = Logger.getLogger(LoginLogController.class.getName());

    @Inject
    AuditLoginLogService auditLoginLogService;

    @POST
    @RunOnVirtualThread
    public Response create(AuditLoginLog request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (auditLoginLogService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                auditLoginLogService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            AuditLoginLog saved = auditLoginLogService.createAuditLoginLog(request);
            if (useKey && saved.getLogId() != null) {
                auditLoginLogService.markHistorySuccess(idempotencyKey, saved.getLogId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                auditLoginLogService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create login log failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response update(@PathParam("logId") Long logId,
                           AuditLoginLog request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setLogId(logId);
            if (useKey) {
                auditLoginLogService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            AuditLoginLog updated = auditLoginLogService.updateAuditLoginLog(request);
            if (useKey && updated.getLogId() != null) {
                auditLoginLogService.markHistorySuccess(idempotencyKey, updated.getLogId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                auditLoginLogService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update login log failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response delete(@PathParam("logId") Long logId) {
        try {
            auditLoginLogService.deleteAuditLoginLog(logId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete login log failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response get(@PathParam("logId") Long logId) {
        try {
            AuditLoginLog log = auditLoginLogService.findById(logId);
            return log == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(log).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get login log failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response list() {
        try {
            return Response.ok(auditLoginLogService.findAll()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List login logs failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/username")
    @RunOnVirtualThread
    public Response searchByUsername(@QueryParam("username") String username,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(auditLoginLogService.searchByUsername(username, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search login log by username failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/result")
    @RunOnVirtualThread
    public Response searchByResult(@QueryParam("result") String result,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(auditLoginLogService.searchByLoginResult(result, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search login log by result failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/time-range")
    @RunOnVirtualThread
    public Response searchByTimeRange(@QueryParam("startTime") String startTime,
                                      @QueryParam("endTime") String endTime,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(auditLoginLogService.searchByLoginTimeRange(startTime, endTime, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search login log by time range failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/ip")
    @RunOnVirtualThread
    public Response searchByIp(@QueryParam("ip") String ip,
                               @QueryParam("page") Integer page,
                               @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(auditLoginLogService.searchByLoginIp(ip, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search login log by IP failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/location")
    @RunOnVirtualThread
    public Response searchByLocation(@QueryParam("loginLocation") String loginLocation,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(auditLoginLogService.searchByLoginLocation(loginLocation, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search login log by location failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/device-type")
    @RunOnVirtualThread
    public Response searchByDeviceType(@QueryParam("deviceType") String deviceType,
                                       @QueryParam("page") Integer page,
                                       @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(auditLoginLogService.searchByDeviceType(deviceType, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search login log by device type failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/browser-type")
    @RunOnVirtualThread
    public Response searchByBrowserType(@QueryParam("browserType") String browserType,
                                        @QueryParam("page") Integer page,
                                        @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(auditLoginLogService.searchByBrowserType(browserType, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search login log by browser type failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/logout-time-range")
    @RunOnVirtualThread
    public Response searchByLogoutTimeRange(@QueryParam("startTime") String startTime,
                                            @QueryParam("endTime") String endTime,
                                            @QueryParam("page") Integer page,
                                            @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(auditLoginLogService.searchByLogoutTimeRange(startTime, endTime, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search login log by logout time range failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
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
