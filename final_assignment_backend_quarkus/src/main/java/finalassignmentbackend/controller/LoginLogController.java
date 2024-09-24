package finalassignmentbackend.controller;


import finalassignmentbackend.entity.LoginLog;
import finalassignmentbackend.service.LoginLogService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.time.LocalDate;
import java.sql.Date;
import java.util.List;

@Path("/eventbus/loginLogs")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class LoginLogController {

    @Inject
    LoginLogService loginLogService;

    @POST
    public Response createLoginLog(LoginLog loginLog) {
        loginLogService.createLoginLog(loginLog);
        return Response.status(Response.Status.CREATED).build();
    }

    @POST
    @Path("/{logId}")
    public Response getLoginLog(@PathParam("logId") int logId) {
        LoginLog loginLog = loginLogService.getLoginLog(logId);
        if (loginLog != null) {
            return Response.ok(loginLog).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    public Response getAllLoginLogs() {
        List<LoginLog> loginLogs = loginLogService.getAllLoginLogs();
        return Response.ok(loginLogs).build();
    }

    @PUT
    @Path("/{logId}")
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
    public Response deleteLoginLog(@PathParam("logId") int logId) {
        loginLogService.deleteLoginLog(logId);
        return Response.noContent().build();
    }

    @GET
    @Path("/timeRange")
    public Response getLoginLogsByTimeRange(
            @QueryParam("startTime") @DefaultValue("1970-01-01") String startTimeStr,
            @QueryParam("endTime") @DefaultValue("9999-12-31") String endTimeStr) {
        try {
            LocalDate startDate = LocalDate.parse(startTimeStr);
            LocalDate endDate = LocalDate.parse(endTimeStr);
            // Convert LocalDate to java.util.Date
            Date startTime = Date.valueOf(startDate);
            Date endTime = Date.valueOf(endDate);

            List<LoginLog> loginLogs = loginLogService.getLoginLogsByTimeRange(startTime, endTime);
            return Response.ok(loginLogs).build();
        } catch (Exception e) {
            return Response.status(Response.Status.BAD_REQUEST).entity("Invalid date format").build();
        }
    }

    @GET
    @Path("/username/{username}")
    public Response getLoginLogsByUsername(@PathParam("username") String username) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByUsername(username);
        return Response.ok(loginLogs).build();
    }

    @GET
    @Path("/loginResult/{loginResult}")
    public Response getLoginLogsByLoginResult(@PathParam("loginResult") String loginResult) {
        List<LoginLog> loginLogs = loginLogService.getLoginLogsByLoginResult(loginResult);
        return Response.ok(loginLogs).build();
    }
}