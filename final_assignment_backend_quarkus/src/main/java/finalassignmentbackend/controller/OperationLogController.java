package finalassignmentbackend.controller;

import finalassignmentbackend.entity.AuditOperationLog;
import finalassignmentbackend.service.AuditOperationLogService;
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

@Path("/api/logs/operation")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Operation Audit", description = "Operation audit log management")
public class OperationLogController {

    private static final Logger LOG = Logger.getLogger(OperationLogController.class.getName());

    @Inject
    AuditOperationLogService auditOperationLogService;

    @POST
    @RunOnVirtualThread
    public Response create(AuditOperationLog request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (auditOperationLogService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                auditOperationLogService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            AuditOperationLog saved = auditOperationLogService.createAuditOperationLog(request);
            if (useKey && saved.getLogId() != null) {
                auditOperationLogService.markHistorySuccess(idempotencyKey, saved.getLogId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                auditOperationLogService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create operation log failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response update(@PathParam("logId") Long logId,
                           AuditOperationLog request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setLogId(logId);
            if (useKey) {
                auditOperationLogService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            AuditOperationLog updated = auditOperationLogService.updateAuditOperationLog(request);
            if (useKey && updated.getLogId() != null) {
                auditOperationLogService.markHistorySuccess(idempotencyKey, updated.getLogId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                auditOperationLogService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update operation log failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response delete(@PathParam("logId") Long logId) {
        try {
            auditOperationLogService.deleteAuditOperationLog(logId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete operation log failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response get(@PathParam("logId") Long logId) {
        try {
            AuditOperationLog log = auditOperationLogService.findById(logId);
            return log == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(log).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get operation log failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response list() {
        try {
            return Response.ok(auditOperationLogService.findAll()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List operation logs failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/module")
    @RunOnVirtualThread
    public Response searchByModule(@QueryParam("module") String module,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(auditOperationLogService.searchByModule(module, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search operation log by module failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/type")
    @RunOnVirtualThread
    public Response searchByType(@QueryParam("type") String type,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(auditOperationLogService.searchByOperationType(type, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search operation log by type failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/user/{userId}")
    @RunOnVirtualThread
    public Response searchByUser(@PathParam("userId") Long userId,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(auditOperationLogService.findByUserId(userId, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search operation log by user failed", ex);
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
            return Response.ok(auditOperationLogService.searchByOperationTimeRange(startTime, endTime, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search operation log by time range failed", ex);
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
            return Response.ok(auditOperationLogService.searchByUsername(username, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search operation log by username failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/request-url")
    @RunOnVirtualThread
    public Response searchByRequestUrl(@QueryParam("requestUrl") String requestUrl,
                                       @QueryParam("page") Integer page,
                                       @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(auditOperationLogService.searchByRequestUrl(requestUrl, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search operation log by request URL failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/request-method")
    @RunOnVirtualThread
    public Response searchByRequestMethod(@QueryParam("requestMethod") String requestMethod,
                                          @QueryParam("page") Integer page,
                                          @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(auditOperationLogService.searchByRequestMethod(requestMethod, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search operation log by request method failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/result")
    @RunOnVirtualThread
    public Response searchByResult(@QueryParam("operationResult") String operationResult,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(auditOperationLogService.searchByOperationResult(operationResult, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search operation log by result failed", ex);
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
