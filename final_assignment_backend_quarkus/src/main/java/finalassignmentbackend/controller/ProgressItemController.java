package finalassignmentbackend.controller;

import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.service.SysRequestHistoryService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/progress")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Progress Tracker", description = "Idempotent request progress endpoints")
public class ProgressItemController {

    private static final Logger LOG = Logger.getLogger(ProgressItemController.class.getName());

    @Inject
    SysRequestHistoryService sysRequestHistoryService;

    @POST
    @RunOnVirtualThread
    public Response create(SysRequestHistory request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (sysRequestHistoryService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                sysRequestHistoryService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            SysRequestHistory saved = sysRequestHistoryService.createSysRequestHistory(request);
            if (useKey && saved.getId() != null) {
                sysRequestHistoryService.markHistorySuccess(idempotencyKey, saved.getId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                sysRequestHistoryService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create request history failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{historyId}")
    @RunOnVirtualThread
    public Response update(@PathParam("historyId") Long historyId,
                           SysRequestHistory request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setId(historyId);
            if (useKey) {
                sysRequestHistoryService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            SysRequestHistory updated = sysRequestHistoryService.updateSysRequestHistory(request);
            if (useKey && updated.getId() != null) {
                sysRequestHistoryService.markHistorySuccess(idempotencyKey, updated.getId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                sysRequestHistoryService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update request history failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{historyId}")
    @RunOnVirtualThread
    public Response delete(@PathParam("historyId") Long historyId) {
        try {
            sysRequestHistoryService.deleteSysRequestHistory(historyId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete request history failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{historyId}")
    @RunOnVirtualThread
    public Response get(@PathParam("historyId") Long historyId) {
        try {
            SysRequestHistory history = sysRequestHistoryService.findById(historyId);
            return history == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(history).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get request history failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response list() {
        try {
            List<SysRequestHistory> items = sysRequestHistoryService.findAll();
            return Response.ok(items).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List request histories failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/status")
    @RunOnVirtualThread
    public Response listByStatus(@QueryParam("status") String status,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(sysRequestHistoryService.findByBusinessStatus(status, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List request histories by status failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/idempotency/{key}")
    @RunOnVirtualThread
    public Response getByIdempotencyKey(@PathParam("key") String key) {
        try {
            Optional<SysRequestHistory> history = sysRequestHistoryService.findByIdempotencyKey(key);
            return history.map(Response::ok)
                    .orElseGet(() -> Response.status(Response.Status.NOT_FOUND))
                    .build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get request history by idempotency key failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
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
