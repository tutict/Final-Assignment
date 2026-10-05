package finalassignmentbackend.controller;

import finalassignmentbackend.entity.DriverInformation;
import finalassignmentbackend.service.driver.DriverInformationService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.annotation.security.RolesAllowed;
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
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/drivers")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Driver Information", description = "Driver information management")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE"})
public class DriverInformationController {

    private static final Logger LOG = Logger.getLogger(DriverInformationController.class.getName());

    @Inject
    DriverInformationService driverInformationService;

    @Inject
    DriverAccessGuard driverAccessGuard;

    @Context
    SecurityContext securityContext;

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
    @Path("/{driverId}/name")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @RunOnVirtualThread
    public Response updateName(@PathParam("driverId") Long driverId,
                               String body,
                               @HeaderParam("Idempotency-Key") String idempotencyKey) {
        return updateDriverField(driverId, "name", body, idempotencyKey);
    }

    @PUT
    @Path("/{driverId}/contactNumber")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @RunOnVirtualThread
    public Response updateContactNumber(@PathParam("driverId") Long driverId,
                                        String body,
                                        @HeaderParam("Idempotency-Key") String idempotencyKey) {
        return updateDriverField(driverId, "contactNumber", body, idempotencyKey);
    }

    @PUT
    @Path("/{driverId}/idCardNumber")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @RunOnVirtualThread
    public Response updateIdCardNumber(@PathParam("driverId") Long driverId,
                                       String body,
                                       @HeaderParam("Idempotency-Key") String idempotencyKey) {
        return updateDriverField(driverId, "idCardNumber", body, idempotencyKey);
    }

    private Response updateDriverField(Long driverId, String field, String body, String idempotencyKey) {
        if (!driverAccessGuard.canAccessDriver(securityContext, driverId)) {
            return driverAccessGuard.forbidden();
        }
        String value = readDriverField(body, field);
        if (value.isBlank()) {
            return Response.status(Response.Status.BAD_REQUEST).build();
        }
        DriverInformation existing = driverInformationService.getDriverById(driverId);
        if (existing == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        switch (field) {
            case "name" -> existing.setName(value);
            case "contactNumber" -> existing.setContactNumber(value);
            case "idCardNumber" -> existing.setIdCardNumber(value);
            default -> {
                return Response.status(Response.Status.BAD_REQUEST).build();
            }
        }
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                driverInformationService.checkAndInsertIdempotency(idempotencyKey, existing, "update");
            }
            DriverInformation updated = driverInformationService.updateDriver(existing);
            if (useKey && updated.getDriverId() != null) {
                driverInformationService.markHistorySuccess(idempotencyKey, updated.getDriverId());
            }
            return Response.noContent().build();
        } catch (RuntimeException ex) {
            if (useKey) {
                driverInformationService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            throw ex;
        }
    }

    private static String readDriverField(String body, String field) {
        if (body == null) {
            return "";
        }
        String text = body.trim();
        if (text.startsWith("\"") && text.endsWith("\"") && text.length() >= 2) {
            return text.substring(1, text.length() - 1).replace("\\\"", "\"").trim();
        }
        String needle = "\"" + field + "\"";
        int key = text.indexOf(needle);
        if (key < 0 && "contactNumber".equals(field)) {
            needle = "\"phoneNumber\"";
            key = text.indexOf(needle);
        }
        if (key < 0) {
            return "";
        }
        int quote = text.indexOf('"', key + needle.length());
        int end = quote < 0 ? -1 : text.indexOf('"', quote + 1);
        return quote < 0 || end < 0 ? "" : text.substring(quote + 1, end).trim();
    }

    @PUT
    @Path("/{driverId}")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @RunOnVirtualThread
    public Response update(@PathParam("driverId") Long driverId,
                           DriverInformation request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (!driverAccessGuard.canAccessDriver(securityContext, driverId)) {
                return driverAccessGuard.forbidden();
            }
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
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @RunOnVirtualThread
    public Response get(@PathParam("driverId") Long driverId) {
        try {
            if (!driverAccessGuard.canAccessDriver(securityContext, driverId)) {
                return driverAccessGuard.forbidden();
            }
            DriverInformation driver = driverInformationService.getDriverById(driverId);
            return driver == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(driver).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get driver failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @RunOnVirtualThread
    public Response list() {
        try {
            if (!driverAccessGuard.isElevated(securityContext)) {
                return Response.ok(driverAccessGuard.scopedOrEmpty(securityContext, id -> {
                    DriverInformation driver = driverInformationService.getDriverById(id);
                    return driver == null ? List.of() : List.of(driver);
                })).build();
            }
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
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @RunOnVirtualThread
    public Response searchByLicense(@QueryParam("keywords") String keywords,
                                    @QueryParam("page") Integer page,
                                    @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            if (!driverAccessGuard.isElevated(securityContext)) {
                return Response.ok(driverAccessGuard.scopedOrEmpty(securityContext, id -> {
                    DriverInformation driver = driverInformationService.getDriverById(id);
                    return driver == null ? List.of() : List.of(driver);
                })).build();
            }
            return Response.ok(driverInformationService.searchByDriverLicenseNumber(keywords, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search driver by license failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/name")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @RunOnVirtualThread
    public Response searchByName(@QueryParam("keywords") String keywords,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            if (!driverAccessGuard.isElevated(securityContext)) {
                return Response.ok(driverAccessGuard.scopedOrEmpty(securityContext, id -> {
                    DriverInformation driver = driverInformationService.getDriverById(id);
                    return driver == null ? List.of() : List.of(driver);
                })).build();
            }
            return Response.ok(driverInformationService.searchByName(keywords, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search driver by name failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @RunOnVirtualThread
    public Response searchDrivers(@QueryParam("keywords") String keywords,
                                  @QueryParam("q") String q,
                                  @QueryParam("page") Integer page,
                                  @QueryParam("size") Integer size) {
        try {
            String resolvedKeywords = keywords != null && !keywords.isBlank() ? keywords : q;
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            if (!driverAccessGuard.isElevated(securityContext)) {
                return Response.ok(driverAccessGuard.scopedOrEmpty(securityContext, id -> {
                    DriverInformation driver = driverInformationService.getDriverById(id);
                    return driver == null ? List.of() : List.of(driver);
                })).build();
            }
            return Response.ok(driverInformationService.searchDrivers(resolvedKeywords, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search drivers failed", ex);
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
