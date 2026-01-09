package finalassignmentbackend.controller;

import finalassignmentbackend.entity.AuditLoginLog;
import finalassignmentbackend.entity.AuditOperationLog;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.service.AuditLoginLogService;
import finalassignmentbackend.service.AuditOperationLogService;
import finalassignmentbackend.service.SysRequestHistoryService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Path("/api/system/logs")
@Produces(MediaType.APPLICATION_JSON)
@Tag(name = "System Logs", description = "System log aggregation endpoints")
public class SystemLogsController {

    private static final Logger LOG = Logger.getLogger(SystemLogsController.class.getName());

    @Inject
    AuditLoginLogService auditLoginLogService;

    @Inject
    AuditOperationLogService auditOperationLogService;

    @Inject
    SysRequestHistoryService sysRequestHistoryService;

    @GET
    @Path("/overview")
    @RunOnVirtualThread
    public Response overview() {
        try {
            Map<String, Object> result = new HashMap<>();
            result.put("loginLogCount", auditLoginLogService.findAll().size());
            result.put("operationLogCount", auditOperationLogService.findAll().size());
            result.put("requestHistoryCount", sysRequestHistoryService.findAll().size());
            return Response.ok(result).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch log overview failed", ex);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GET
    @Path("/login/recent")
    @RunOnVirtualThread
    public Response recentLoginLogs(@QueryParam("limit") Integer limit) {
        try {
            int resolved = limit == null ? 10 : Math.max(limit, 1);
            List<AuditLoginLog> recent = auditLoginLogService.findAll().stream()
                    .limit(resolved)
                    .collect(Collectors.toList());
            return Response.ok(recent).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch recent login logs failed", ex);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GET
    @Path("/operation/recent")
    @RunOnVirtualThread
    public Response recentOperationLogs(@QueryParam("limit") Integer limit) {
        try {
            int resolved = limit == null ? 10 : Math.max(limit, 1);
            List<AuditOperationLog> recent = auditOperationLogService.findAll().stream()
                    .limit(resolved)
                    .collect(Collectors.toList());
            return Response.ok(recent).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch recent operation logs failed", ex);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GET
    @Path("/requests/{historyId}")
    @RunOnVirtualThread
    public Response requestHistory(@PathParam("historyId") Long historyId) {
        try {
            SysRequestHistory history = sysRequestHistoryService.findById(historyId);
            return history == null
                    ? Response.status(Response.Status.NOT_FOUND).build()
                    : Response.ok(history).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch request history failed", ex);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GET
    @Path("/requests/search/idempotency")
    @RunOnVirtualThread
    public Response searchByIdempotency(@QueryParam("key") String key,
                                        @QueryParam("page") Integer page,
                                        @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRequestHistoryService.searchByIdempotencyKey(key, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/requests/search/method")
    @RunOnVirtualThread
    public Response searchByRequestMethod(@QueryParam("requestMethod") String requestMethod,
                                          @QueryParam("page") Integer page,
                                          @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRequestHistoryService.searchByRequestMethod(requestMethod, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/requests/search/url")
    @RunOnVirtualThread
    public Response searchByRequestUrl(@QueryParam("requestUrl") String requestUrl,
                                       @QueryParam("page") Integer page,
                                       @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRequestHistoryService.searchByRequestUrlPrefix(requestUrl, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/requests/search/business-type")
    @RunOnVirtualThread
    public Response searchByBusinessType(@QueryParam("businessType") String businessType,
                                         @QueryParam("page") Integer page,
                                         @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRequestHistoryService.searchByBusinessType(businessType, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/requests/search/business-id")
    @RunOnVirtualThread
    public Response searchByBusinessId(@QueryParam("businessId") Long businessId,
                                       @QueryParam("page") Integer page,
                                       @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRequestHistoryService.findByBusinessId(businessId, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/requests/search/status")
    @RunOnVirtualThread
    public Response searchByBusinessStatus(@QueryParam("status") String status,
                                           @QueryParam("page") Integer page,
                                           @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRequestHistoryService.findByBusinessStatus(status, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/requests/search/user")
    @RunOnVirtualThread
    public Response searchByUser(@QueryParam("userId") Long userId,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRequestHistoryService.findByUserId(userId, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/requests/search/ip")
    @RunOnVirtualThread
    public Response searchByRequestIp(@QueryParam("requestIp") String requestIp,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRequestHistoryService.searchByRequestIp(requestIp, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/requests/search/time-range")
    @RunOnVirtualThread
    public Response searchByCreatedTimeRange(@QueryParam("startTime") String startTime,
                                             @QueryParam("endTime") String endTime,
                                             @QueryParam("page") Integer page,
                                             @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysRequestHistoryService.searchByCreatedAtRange(startTime, endTime, resolvedPage, resolvedSize)).build();
    }
}
