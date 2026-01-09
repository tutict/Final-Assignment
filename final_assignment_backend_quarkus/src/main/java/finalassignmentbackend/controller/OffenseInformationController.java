package finalassignmentbackend.controller;

import finalassignmentbackend.entity.OffenseRecord;
import finalassignmentbackend.service.OffenseRecordService;
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

@Path("/api/offenses")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Offense Management", description = "Offense Management Controller for managing offense records")
public class OffenseInformationController {

    private static final Logger LOG = Logger.getLogger(OffenseInformationController.class.getName());

    @Inject
    OffenseRecordService offenseRecordService;

    @POST
    @RunOnVirtualThread
    public Response create(OffenseRecord request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (offenseRecordService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                offenseRecordService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            OffenseRecord saved = offenseRecordService.createOffenseRecord(request);
            if (useKey && saved.getOffenseId() != null) {
                offenseRecordService.markHistorySuccess(idempotencyKey, saved.getOffenseId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                offenseRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create offense failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{offenseId}")
    @RunOnVirtualThread
    public Response update(@PathParam("offenseId") Long offenseId,
                           OffenseRecord request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setOffenseId(offenseId);
            if (useKey) {
                offenseRecordService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            OffenseRecord updated = offenseRecordService.updateOffenseRecord(request);
            if (useKey && updated.getOffenseId() != null) {
                offenseRecordService.markHistorySuccess(idempotencyKey, updated.getOffenseId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                offenseRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update offense failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{offenseId}")
    @RunOnVirtualThread
    public Response delete(@PathParam("offenseId") Long offenseId) {
        try {
            offenseRecordService.deleteOffenseRecord(offenseId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete offense failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{offenseId}")
    @RunOnVirtualThread
    public Response get(@PathParam("offenseId") Long offenseId) {
        try {
            OffenseRecord record = offenseRecordService.findById(offenseId);
            return record == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(record).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get offense failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response list() {
        try {
            return Response.ok(offenseRecordService.findAll()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List offenses failed", ex);
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
            return Response.ok(offenseRecordService.findByDriverId(driverId, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List offenses by driver failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/vehicle/{vehicleId}")
    @RunOnVirtualThread
    public Response byVehicle(@PathParam("vehicleId") Long vehicleId,
                              @QueryParam("page") Integer page,
                              @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(offenseRecordService.findByVehicleId(vehicleId, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List offenses by vehicle failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/code")
    @RunOnVirtualThread
    public Response searchByCode(@QueryParam("offenseCode") String offenseCode,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(offenseRecordService.searchByOffenseCode(offenseCode, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by code failed", ex);
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
            return Response.ok(offenseRecordService.searchByProcessStatus(status, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by status failed", ex);
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
            return Response.ok(offenseRecordService.searchByOffenseTimeRange(startTime, endTime, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by time range failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/number")
    @RunOnVirtualThread
    public Response searchByNumber(@QueryParam("offenseNumber") String offenseNumber,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(offenseRecordService.searchByOffenseNumber(offenseNumber, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by number failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/location")
    @RunOnVirtualThread
    public Response searchByLocation(@QueryParam("offenseLocation") String offenseLocation,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(offenseRecordService.searchByOffenseLocation(offenseLocation, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by location failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/province")
    @RunOnVirtualThread
    public Response searchByProvince(@QueryParam("offenseProvince") String offenseProvince,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(offenseRecordService.searchByOffenseProvince(offenseProvince, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by province failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/city")
    @RunOnVirtualThread
    public Response searchByCity(@QueryParam("offenseCity") String offenseCity,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(offenseRecordService.searchByOffenseCity(offenseCity, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by city failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/notification")
    @RunOnVirtualThread
    public Response searchByNotification(@QueryParam("notificationStatus") String notificationStatus,
                                         @QueryParam("page") Integer page,
                                         @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(offenseRecordService.searchByNotificationStatus(notificationStatus, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by notification status failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/agency")
    @RunOnVirtualThread
    public Response searchByAgency(@QueryParam("enforcementAgency") String enforcementAgency,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(offenseRecordService.searchByEnforcementAgency(enforcementAgency, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by enforcement agency failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/fine-range")
    @RunOnVirtualThread
    public Response searchByFineRange(@QueryParam("minAmount") double minAmount,
                                      @QueryParam("maxAmount") double maxAmount,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(offenseRecordService.searchByFineAmountRange(minAmount, maxAmount, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by fine amount range failed", ex);
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
