package finalassignmentbackend.controller;

import finalassignmentbackend.entity.FineRecord;
import finalassignmentbackend.service.FineRecordService;
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

@Path("/api/fines")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Fine Management", description = "Fine record management")
public class FineInformationController {

    private static final Logger LOG = Logger.getLogger(FineInformationController.class.getName());

    @Inject
    FineRecordService fineRecordService;

    @POST
    @RunOnVirtualThread
    public Response create(FineRecord request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (fineRecordService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                fineRecordService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            FineRecord saved = fineRecordService.createFineRecord(request);
            if (useKey && saved.getFineId() != null) {
                fineRecordService.markHistorySuccess(idempotencyKey, saved.getFineId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                fineRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create fine failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{fineId}")
    @RunOnVirtualThread
    public Response update(@PathParam("fineId") Long fineId,
                           FineRecord request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setFineId(fineId);
            if (useKey) {
                fineRecordService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            FineRecord updated = fineRecordService.updateFineRecord(request);
            if (useKey && updated.getFineId() != null) {
                fineRecordService.markHistorySuccess(idempotencyKey, updated.getFineId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                fineRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update fine failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{fineId}")
    @RunOnVirtualThread
    public Response delete(@PathParam("fineId") Long fineId) {
        try {
            fineRecordService.deleteFineRecord(fineId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete fine failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{fineId}")
    @RunOnVirtualThread
    public Response get(@PathParam("fineId") Long fineId) {
        try {
            FineRecord record = fineRecordService.findById(fineId);
            return record == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(record).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get fine failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response list() {
        try {
            return Response.ok(fineRecordService.findAll()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List fines failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/offense/{offenseId}")
    @RunOnVirtualThread
    public Response byOffense(@PathParam("offenseId") Long offenseId,
                              @QueryParam("page") Integer page,
                              @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(fineRecordService.findByOffenseId(offenseId, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List fines by offense failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/handler")
    @RunOnVirtualThread
    public Response searchByHandler(@QueryParam("handler") String handler,
                                    @QueryParam("mode") String mode,
                                    @QueryParam("page") Integer page,
                                    @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            List<FineRecord> result = "fuzzy".equalsIgnoreCase(mode)
                    ? fineRecordService.searchByHandlerFuzzy(handler, resolvedPage, resolvedSize)
                    : fineRecordService.searchByHandlerPrefix(handler, resolvedPage, resolvedSize);
            return Response.ok(result).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search fine by handler failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/status")
    @RunOnVirtualThread
    public Response searchByPaymentStatus(@QueryParam("status") String status,
                                          @QueryParam("page") Integer page,
                                          @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(fineRecordService.searchByPaymentStatus(status, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search fine by status failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/date-range")
    @RunOnVirtualThread
    public Response searchByDateRange(@QueryParam("startDate") String startDate,
                                      @QueryParam("endDate") String endDate,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(fineRecordService.searchByFineDateRange(startDate, endDate, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search fine by date range failed", ex);
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
