package finalassignmentbackend.controller;

import finalassignmentbackend.entity.SysBackupRestore;
import finalassignmentbackend.service.SysBackupRestoreService;
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
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Path("/api/system/backup")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Backup & Restore", description = "System backup and restore management")
public class BackupRestoreController {

    private static final Logger LOG = Logger.getLogger(BackupRestoreController.class.getName());

    @Inject
    SysBackupRestoreService backupRestoreService;

    @POST
    @RunOnVirtualThread
    public Response create(SysBackupRestore request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (backupRestoreService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                backupRestoreService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            SysBackupRestore saved = backupRestoreService.createSysBackupRestore(request);
            if (useKey && saved.getBackupId() != null) {
                backupRestoreService.markHistorySuccess(idempotencyKey, saved.getBackupId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                backupRestoreService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create backup task failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{backupId}")
    @RunOnVirtualThread
    public Response update(@PathParam("backupId") Long backupId,
                           SysBackupRestore request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setBackupId(backupId);
            if (useKey) {
                backupRestoreService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            SysBackupRestore updated = backupRestoreService.updateSysBackupRestore(request);
            if (useKey && updated.getBackupId() != null) {
                backupRestoreService.markHistorySuccess(idempotencyKey, updated.getBackupId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                backupRestoreService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update backup task failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{backupId}")
    @RunOnVirtualThread
    public Response delete(@PathParam("backupId") Long backupId) {
        try {
            backupRestoreService.deleteSysBackupRestore(backupId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete backup task failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{backupId}")
    @RunOnVirtualThread
    public Response get(@PathParam("backupId") Long backupId) {
        try {
            SysBackupRestore record = backupRestoreService.findById(backupId);
            return record == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(record).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get backup task failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response list(@QueryParam("status") String status) {
        try {
            List<SysBackupRestore> all = backupRestoreService.findAll();
            if (status == null || status.isBlank()) {
                return Response.ok(all).build();
            }
            List<SysBackupRestore> filtered = all.stream()
                    .filter(item -> status.equalsIgnoreCase(item.getStatus()))
                    .collect(Collectors.toList());
            return Response.ok(filtered).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List backup tasks failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/type")
    @RunOnVirtualThread
    public Response searchByType(@QueryParam("backupType") String backupType,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(backupRestoreService.searchByBackupType(backupType, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/file-name")
    @RunOnVirtualThread
    public Response searchByFileName(@QueryParam("backupFileName") String backupFileName,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(backupRestoreService.searchByBackupFileNamePrefix(backupFileName, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/handler")
    @RunOnVirtualThread
    public Response searchByHandler(@QueryParam("backupHandler") String backupHandler,
                                    @QueryParam("page") Integer page,
                                    @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(backupRestoreService.searchByBackupHandler(backupHandler, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/restore-status")
    @RunOnVirtualThread
    public Response searchByRestoreStatus(@QueryParam("restoreStatus") String restoreStatus,
                                          @QueryParam("page") Integer page,
                                          @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(backupRestoreService.searchByRestoreStatus(restoreStatus, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/status")
    @RunOnVirtualThread
    public Response searchByStatus(@QueryParam("status") String status,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(backupRestoreService.searchByStatus(status, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/backup-time-range")
    @RunOnVirtualThread
    public Response searchByBackupTimeRange(@QueryParam("startTime") String startTime,
                                            @QueryParam("endTime") String endTime,
                                            @QueryParam("page") Integer page,
                                            @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(backupRestoreService.searchByBackupTimeRange(startTime, endTime, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/restore-time-range")
    @RunOnVirtualThread
    public Response searchByRestoreTimeRange(@QueryParam("startTime") String startTime,
                                             @QueryParam("endTime") String endTime,
                                             @QueryParam("page") Integer page,
                                             @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(backupRestoreService.searchByRestoreTimeRange(startTime, endTime, resolvedPage, resolvedSize)).build();
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
