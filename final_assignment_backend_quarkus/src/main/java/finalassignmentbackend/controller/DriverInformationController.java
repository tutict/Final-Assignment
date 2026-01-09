package finalassignmentbackend.controller;

import finalassignmentbackend.entity.DriverInformation;
import finalassignmentbackend.service.DriverInformationService;
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

@Path("/api/drivers")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Driver Information", description = "Driver information management")
public class DriverInformationController {

    private static final Logger LOG = Logger.getLogger(DriverInformationController.class.getName());

    @Inject
    DriverInformationService driverInformationService;

    @POST
    @RunOnVirtualThread
    public Response create(DriverInformation request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (driverInformationService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                driverInformationService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            DriverInformation saved = driverInformationService.createDriver(request);
            if (useKey && saved.getDriverId() != null) {
                driverInformationService.markHistorySuccess(idempotencyKey, saved.getDriverId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                driverInformationService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create driver failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{driverId}")
    @RunOnVirtualThread
    public Response update(@PathParam("driverId") Long driverId,
                           DriverInformation request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setDriverId(driverId);
            if (useKey) {
                driverInformationService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            DriverInformation updated = driverInformationService.updateDriver(request);
            if (useKey && updated.getDriverId() != null) {
                driverInformationService.markHistorySuccess(idempotencyKey, updated.getDriverId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                driverInformationService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update driver failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{driverId}")
    @RunOnVirtualThread
    public Response delete(@PathParam("driverId") Long driverId) {
        try {
            driverInformationService.deleteDriver(driverId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete driver failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{driverId}")
    @RunOnVirtualThread
    public Response get(@PathParam("driverId") Long driverId) {
        try {
            DriverInformation driver = driverInformationService.getDriverById(driverId);
            return driver == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(driver).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get driver failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response list() {
        try {
            return Response.ok(driverInformationService.getAllDrivers()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List drivers failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/id-card")
    @RunOnVirtualThread
    public Response searchByIdCard(@QueryParam("keywords") String keywords,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(driverInformationService.searchByIdCardNumber(keywords, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search driver by id card failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/license")
    @RunOnVirtualThread
    public Response searchByLicense(@QueryParam("keywords") String keywords,
                                    @QueryParam("page") Integer page,
                                    @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(driverInformationService.searchByDriverLicenseNumber(keywords, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search driver by license failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/name")
    @RunOnVirtualThread
    public Response searchByName(@QueryParam("keywords") String keywords,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(driverInformationService.searchByName(keywords, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search driver by name failed", ex);
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
