package finalassignmentbackend.controller;

import finalassignmentbackend.entity.SystemLogs;
import finalassignmentbackend.service.SystemLogsService;
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

import java.util.Date;
import java.util.List;

@Path("/api/systemLogs")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "System Logs", description = "System Logs Controller for managing system logs")
public class SystemLogsController {

    @Inject
    SystemLogsService systemLogsService;

    @POST
    @RunOnVirtualThread
    public Response createSystemLog(SystemLogs systemLog, @QueryParam("idempotencyKey") String idempotencyKey) {
        systemLogsService.checkAndInsertIdempotency(idempotencyKey, systemLog, "create");
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response getSystemLogById(@PathParam("logId") int logId) {
        SystemLogs systemLog = systemLogsService.getSystemLogById(logId);
        if (systemLog != null) {
            return Response.ok(systemLog).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response getAllSystemLogs() {
        List<SystemLogs> systemLogs = systemLogsService.getAllSystemLogs();
        return Response.ok(systemLogs).build();
    }

    @GET
    @Path("/type/{logType}")
    @RunOnVirtualThread
    public Response getSystemLogsByType(@PathParam("logType") String logType) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByType(logType);
        return Response.ok(systemLogs).build();
    }

    @GET
    @Path("/timeRange")
    @RunOnVirtualThread
    public Response getSystemLogsByTimeRange(
            @QueryParam("startTime") Date startTime,
            @QueryParam("endTime") Date endTime) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByTimeRange(startTime, endTime);
        return Response.ok(systemLogs).build();
    }

    @GET
    @Path("/operationUser/{operationUser}")
    @RunOnVirtualThread
    public Response getSystemLogsByOperationUser(@PathParam("operationUser") String operationUser) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByOperationUser(operationUser);
        return Response.ok(systemLogs).build();
    }

    @PUT
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response updateSystemLog(@PathParam("logId") int logId, SystemLogs updatedSystemLog, @QueryParam("idempotencyKey") String idempotencyKey) {
        SystemLogs existingSystemLog = systemLogsService.getSystemLogById(logId);
        if (existingSystemLog != null) {
            updatedSystemLog.setLogId(logId);
            systemLogsService.checkAndInsertIdempotency(idempotencyKey, updatedSystemLog, "update");
            return Response.ok(Response.Status.OK).entity(updatedSystemLog).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response deleteSystemLog(@PathParam("logId") int logId) {
        systemLogsService.deleteSystemLog(logId);
        return Response.noContent().build();
    }
}
