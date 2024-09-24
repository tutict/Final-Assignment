package finalassignmentbackend.controller;

import finalassignmentbackend.entity.OperationLog;
import finalassignmentbackend.service.OperationLogService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.time.LocalDate;
import java.util.List;

@Path("/eventbus/operationLogs")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class OperationLogController {

    @Inject
    OperationLogService operationLogService;

    @POST
    public Response createOperationLog(OperationLog operationLog) {
        operationLogService.createOperationLog(operationLog);
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{logId}")
    public Response getOperationLog(@PathParam("logId") int logId) {
        OperationLog operationLog = operationLogService.getOperationLog(logId);
        if (operationLog != null) {
            return Response.ok(operationLog).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    public Response getAllOperationLogs() {
        List<OperationLog> operationLogs = operationLogService.getAllOperationLogs();
        return Response.ok(operationLogs).build();
    }

    @PUT
    @Path("/{logId}")
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
    public Response deleteOperationLog(@PathParam("logId") int logId) {
        operationLogService.deleteOperationLog(logId);
        return Response.noContent().build();
    }


    @GET
    @Path("/timeRange")
    public Response getDeductionsByTimeRange(
            @QueryParam("startTime") @DefaultValue("1970-01-01") String startTimeStr,
            @QueryParam("endTime") @DefaultValue("2100-12-31") String endTimeStr) {
        try {
            LocalDate startDate = LocalDate.parse(startTimeStr);
            LocalDate endDate = LocalDate.parse(endTimeStr);

            // Convert LocalDate to java.util.Date
            java.sql.Date startTime = java.sql.Date.valueOf(startDate);
            java.sql.Date endTime = java.sql.Date.valueOf(endDate);

            List<OperationLog> operationLogs = operationLogService.getOperationLogsByTimeRange(startTime, endTime);
            return Response.ok(operationLogs).build();
        } catch (Exception e) {
            return Response.status(Response.Status.BAD_REQUEST).entity("Invalid date format").build();
        }
    }

    @GET
    @Path("/userId/{userId}")
    public Response getOperationLogsByUserId(@PathParam("userId") String userId) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByUserId(userId);
        return Response.ok(operationLogs).build();
    }

    @GET
    @Path("/result/{result}")
    public Response getOperationLogsByResult(@PathParam("result") String result) {
        List<OperationLog> operationLogs = operationLogService.getOperationLogsByResult(result);
        return Response.ok(operationLogs).build();
    }
}