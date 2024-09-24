package finalassignmentbackend.controller;


import finalassignmentbackend.entity.SystemSettings;
import finalassignmentbackend.service.SystemSettingsService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@Path("/eventbus/systemSettings")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class SystemSettingsController {

    @Inject
    SystemSettingsService systemSettingsService;

    @GET
    public Response getSystemSettings() {
        SystemSettings systemSettings = systemSettingsService.getSystemSettings();
        if (systemSettings != null) {
            return Response.ok(systemSettings).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @PUT
    public Response updateSystemSettings(SystemSettings systemSettings) {
        systemSettingsService.updateSystemSettings(systemSettings);
        return Response.ok().build();
    }

    @GET
    @Path("/systemName")
    public Response getSystemName() {
        String systemName = systemSettingsService.getSystemName();
        if (systemName != null) {
            return Response.ok(systemName).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/systemVersion")
    public Response getSystemVersion() {
        String systemVersion = systemSettingsService.getSystemVersion();
        if (systemVersion != null) {
            return Response.ok(systemVersion).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/systemDescription")
    public Response getSystemDescription() {
        String systemDescription = systemSettingsService.getSystemDescription();
        if (systemDescription != null) {
            return Response.ok(systemDescription).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/copyrightInfo")
    public Response getCopyrightInfo() {
        String copyrightInfo = systemSettingsService.getCopyrightInfo();
        if (copyrightInfo != null) {
            return Response.ok(copyrightInfo).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/storagePath")
    public Response getStoragePath() {
        String storagePath = systemSettingsService.getStoragePath();
        if (storagePath != null) {
            return Response.ok(storagePath).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/loginTimeout")
    public Response getLoginTimeout() {
        int loginTimeout = systemSettingsService.getLoginTimeout();
        return Response.ok(loginTimeout).build();
    }

    @GET
    @Path("/sessionTimeout")
    public Response getSessionTimeout() {
        int sessionTimeout = systemSettingsService.getSessionTimeout();
        return Response.ok(sessionTimeout).build();
    }

    @GET
    @Path("/dateFormat")
    public Response getDateFormat() {
        String dateFormat = systemSettingsService.getDateFormat();
        if (dateFormat != null) {
            return Response.ok(dateFormat).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/pageSize")
    public Response getPageSize() {
        int pageSize = systemSettingsService.getPageSize();
        return Response.ok(pageSize).build();
    }

    @GET
    @Path("/smtpServer")
    public Response getSmtpServer() {
        String smtpServer = systemSettingsService.getSmtpServer();
        if (smtpServer != null) {
            return Response.ok(smtpServer).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/emailAccount")
    public Response getEmailAccount() {
        String emailAccount = systemSettingsService.getEmailAccount();
        if (emailAccount != null) {
            return Response.ok(emailAccount).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/emailPassword")
    public Response getEmailPassword() {
        String emailPassword = systemSettingsService.getEmailPassword();
        if (emailPassword != null) {
            return Response.ok(emailPassword).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }
}
