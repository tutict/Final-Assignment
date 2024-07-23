package finalassignmentbackend.controller;


import finalassignmentbackend.entity.BackupRestore;
import finalassignmentbackend.service.BackupRestoreService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;

@Path("/eventbus/backups")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class BackupRestoreController {

    @Inject
    BackupRestoreService backupRestoreService;

    @POST
    public Response createBackup(BackupRestore backup) {
        backupRestoreService.createBackup(backup);
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    public Response getAllBackups() {
        List<BackupRestore> backups = backupRestoreService.getAllBackups();
        return Response.ok(backups).build();
    }

    @GET
    @Path("/{backupId}")
    public Response getBackupById(@PathParam("backupId") int backupId) {
        BackupRestore backup = backupRestoreService.getBackupById(backupId);
        if (backup != null) {
            return Response.ok(backup).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{backupId}")
    public Response deleteBackup(@PathParam("backupId") int backupId) {
        backupRestoreService.deleteBackup(backupId);
        return Response.noContent().build();
    }

    @PUT
    @Path("/{backupId}")
    public Response updateBackup(@PathParam("backupId") int backupId, BackupRestore updatedBackup) {
        BackupRestore existingBackup = backupRestoreService.getBackupById(backupId);
        if (existingBackup != null) {
            updatedBackup.setBackupId(backupId);
            backupRestoreService.updateBackup(updatedBackup);
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/filename/{backupFileName}")
    public Response getBackupByFileName(@PathParam("backupFileName") String backupFileName) {
        BackupRestore backup = backupRestoreService.getupByFileName(backupFileName);
        if (backup != null) {
            return Response.ok(backup).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/time/{backupTime}")
    public Response getBackupsByTime(@PathParam("backupTime") String backupTime) {
        List<BackupRestore> backups = backupRestoreService.getBackupsByTime(backupTime);
        return Response.ok(backups).build();
    }
}