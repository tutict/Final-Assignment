package finalassignmentbackend.controller;

import finalassignmentbackend.entity.LoginLog;
import finalassignmentbackend.service.LoginLogService;
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

@Path("/eventbus/loginLogs")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class LoginLogController {

    @Inject
    LoginLogService loginLogService;

    @POST
    @RunOnVirtualThread
    public Response createLoginLog(LoginLog loginLog) {
        loginLogService.createLoginLog(loginLog);
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response getLoginLog(@PathParam("logId") int logId) {
        LoginLog loginLog = loginLogService.getLoginLog(logId);
        if (loginLog != null) {
            return Response.ok(loginLog).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response getAllLoginLogs() {
        List<LoginLog> loginLogs = loginLogService.getAllLoginLogs();
        return Response.ok(loginLogs).build();
    }

    @PUT
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response updateLoginLog(@PathParam("logId") int logId, LoginLog updatedLoginLog) {
        LoginLog existingLoginLog = loginLogService.getLoginLog(logId);
        if (existingLoginLog != null) {
            updatedLoginLog.setLogId(logId);
            loginLogService.updateLoginLog(updatedLoginLog);
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{logId}")
    @RunOnVirtualThread
    public Response deleteLoginLog(@PathParam("logId") int logId) {
        loginLogService.deleteLoginLog(logId);
        return Response.noContent().build();
    }

    @GET
    @Path("/timeRange")
    @RunOnVirtualThread
    public Response getLoginLogsByTimeRange(@QueryParam("startTime") @DefaultValue("1970-01-01") Date startTime,
                                            @QueryParam("endTime") @DefaultValue("2100-01-01") Date endTime) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByTimeRange(startTime, endTime);
        return Response.ok(loginLogs).build();
    }

    @GET
    @Path("/username/{username}")
    @RunOnVirtualThread
    public Response getLoginLogsByUsername(@PathParam("username") String username) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByUsername(username);
        return Response.ok(loginLogs).build();
    }

    @GET
    @Path("/loginResult/{loginResult}")
    @RunOnVirtualThread
    public Response getLoginLogsByLoginResult(@PathParam("loginResult") String loginResult) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByLoginResult(loginResult);
        return Response.ok(loginLogs).build();
    }
}
