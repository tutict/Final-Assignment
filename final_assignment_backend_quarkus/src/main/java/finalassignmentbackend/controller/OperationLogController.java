package finalassignmentbackend.controller;

import finalassignmentbackend.entity.OperationLog;
import finalassignmentbackend.service.OperationLogService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.Date;
import java.util.List;

@Path("/api/operationLogs")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class OperationLogController {

    @Inject
    OperationLogService operationLogService;

    @POST
    @RunOnVirtualThread
    public Response createOperationLog(OperationLog operationLog) {
        operationLogService.createOperationLog(operationLog);
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response getOperationLog(@PathParam("logId") int logId) {
        OperationLog operationLog = operationLogService.getOperationLog(logId);
        if (operationLog != null) {
            return Response.ok(operationLog).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response getAllOperationLogs() {
        List<OperationLog> operationLogs = operationLogService.getAllOperationLogs();
        return Response.ok(operationLogs).build();
    }

    @PUT
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response updateOperationLog(@PathParam("logId") int logId, OperationLog updatedOperationLog) {
        OperationLog existingOperationLog = operationLogService.getOperationLog(logId);
        if (existingOperationLog != null) {
            updatedOperationLog.setLogId(logId);
            operationLogService.updateOperationLog(updatedOperationLog);
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response deleteOperationLog(@PathParam("logId") int logId) {
        operationLogService.deleteOperationLog(logId);
        return Response.noContent().build();
    }

    @GET
    @Path("/timeRange")
    @RunOnVirtualThread
    public Response getOperationLogsByTimeRange(@QueryParam("startTime") @DefaultValue("1970-01-01") Date startTime,
                                                @QueryParam("endTime") @DefaultValue("2100-01-01") Date endTime) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByTimeRange(startTime, endTime);
        return Response.ok(operationLogs).build();
    }

    @GET
    @Path("/userId/{userId}")
    @RunOnVirtualThread
    public Response getOperationLogsByUserId(@PathParam("userId") String userId) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByUserId(userId);
        return Response.ok(operationLogs).build();
    }

    @GET
    @Path("/result/{result}")
    @RunOnVirtualThread
    public Response getOperationLogsByResult(@PathParam("result") String result) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByResult(result);
        return Response.ok(operationLogs).build();
    }
}
