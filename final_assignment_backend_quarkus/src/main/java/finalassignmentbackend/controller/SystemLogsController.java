package finalassignmentbackend.controller;

import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.SystemLogs;
import finalassignmentbackend.service.SystemLogsService;
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

import java.util.Date;
import java.util.List;

@Path("/eventbus/systemLogs")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class SystemLogsController {

    @Inject
    SystemLogsService systemLogsService;

    @POST
    public Response createSystemLog(SystemLogs systemLog) {
        systemLogsService.createSystemLog(systemLog);
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{logId}")
    public Response getSystemLogById(@PathParam("logId") int logId) {
        SystemLogs systemLog = systemLogsService.getSystemLogById(logId);
        if (systemLog != null) {
            return Response.ok(systemLog).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    public Response getAllSystemLogs() {
        List<SystemLogs> systemLogs = systemLogsService.getAllSystemLogs();
        return Response.ok(systemLogs).build();
    }

    @GET
    @Path("/type/{logType}")
    public Response getSystemLogsByType(@PathParam("logType") String logType) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByType(logType);
        return Response.ok(systemLogs).build();
    }

    @GET
    @Path("/timeRange")
    public Response getSystemLogsByTimeRange(
            @QueryParam("startTime") Date startTime,
            @QueryParam("endTime") Date endTime) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByTimeRange(startTime, endTime);
        return Response.ok(systemLogs).build();
    }

    @GET
    @Path("/operationUser/{operationUser}")
    public Response getSystemLogsByOperationUser(@PathParam("operationUser") String operationUser) {
        List<SystemLogs> systemLogs = systemLogsService.getSystemLogsByOperationUser(operationUser);
        return Response.ok(systemLogs).build();
    }

    @PUT
    @Path("/{logId}")
    public Response updateSystemLog(@PathParam("logId") int logId, SystemLogs updatedSystemLog) {
        SystemLogs existingSystemLog = systemLogsService.getSystemLogById(logId);
        if (existingSystemLog != null) {
            updatedSystemLog.setLogId(logId);
            systemLogsService.updateSystemLog(updatedSystemLog);
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{logId}")
    public Response deleteSystemLog(@PathParam("logId") int logId) {
        systemLogsService.deleteSystemLog(logId);
        return Response.noContent().build();
    }
}
