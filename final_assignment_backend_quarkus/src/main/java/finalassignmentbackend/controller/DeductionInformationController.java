package finalassignmentbackend.controller;

import finalassignmentbackend.entity.DeductionRecord;
import finalassignmentbackend.service.DeductionRecordService;
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

@Path("/api/deductions")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Deduction Management", description = "Deduction record management")
public class DeductionInformationController {

    private static final Logger LOG = Logger.getLogger(DeductionInformationController.class.getName());

    @Inject
    DeductionRecordService deductionRecordService;

    @POST
    @RunOnVirtualThread
    public Response create(DeductionRecord request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (deductionRecordService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                deductionRecordService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            DeductionRecord saved = deductionRecordService.createDeductionRecord(request);
            if (useKey && saved.getDeductionId() != null) {
                deductionRecordService.markHistorySuccess(idempotencyKey, saved.getDeductionId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                deductionRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create deduction failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{deductionId}")
    @RunOnVirtualThread
    public Response update(@PathParam("deductionId") Long deductionId,
                           DeductionRecord request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setDeductionId(deductionId);
            if (useKey) {
                deductionRecordService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            DeductionRecord updated = deductionRecordService.updateDeductionRecord(request);
            if (useKey && updated.getDeductionId() != null) {
                deductionRecordService.markHistorySuccess(idempotencyKey, updated.getDeductionId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                deductionRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update deduction failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{deductionId}")
    @RunOnVirtualThread
    public Response delete(@PathParam("deductionId") Long deductionId) {
        try {
            deductionRecordService.deleteDeductionRecord(deductionId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete deduction failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{deductionId}")
    @RunOnVirtualThread
    public Response get(@PathParam("deductionId") Long deductionId) {
        try {
            DeductionRecord record = deductionRecordService.findById(deductionId);
            return record == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(record).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get deduction failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response list() {
        try {
            return Response.ok(deductionRecordService.findAll()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List deductions failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/driver/{driverId}")
    @RunOnVirtualThread
    public Response byDriver(@PathParam("driverId") Long driverId,
                             @QueryParam("page") Integer page,
                             @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(deductionRecordService.findByDriverId(driverId, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List deductions by driver failed", ex);
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
            return Response.ok(deductionRecordService.findByOffenseId(offenseId, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List deductions by offense failed", ex);
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
            List<DeductionRecord> result = "fuzzy".equalsIgnoreCase(mode)
                    ? deductionRecordService.searchByHandlerFuzzy(handler, resolvedPage, resolvedSize)
                    : deductionRecordService.searchByHandlerPrefix(handler, resolvedPage, resolvedSize);
            return Response.ok(result).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search deduction by handler failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/status")
    @RunOnVirtualThread
    public Response searchByStatus(@QueryParam("status") String status,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(deductionRecordService.searchByStatus(status, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search deduction by status failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/time-range")
    @RunOnVirtualThread
    public Response searchByTimeRange(@QueryParam("startTime") String startTime,
                                      @QueryParam("endTime") String endTime,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(deductionRecordService.searchByDeductionTimeRange(startTime, endTime, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search deduction by time range failed", ex);
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
