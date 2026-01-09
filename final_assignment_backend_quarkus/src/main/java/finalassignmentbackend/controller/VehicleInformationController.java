package finalassignmentbackend.controller;

import finalassignmentbackend.entity.DriverVehicle;
import finalassignmentbackend.entity.VehicleInformation;
import finalassignmentbackend.service.DriverVehicleService;
import finalassignmentbackend.service.VehicleInformationService;
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
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/vehicles")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Vehicle Information", description = "Vehicle information and binding management")
public class VehicleInformationController {

    private static final Logger LOG = Logger.getLogger(VehicleInformationController.class.getName());

    @Inject
    VehicleInformationService vehicleInformationService;

    @Inject
    DriverVehicleService driverVehicleService;

    @POST
    @RunOnVirtualThread
    public Response createVehicle(VehicleInformation request,
                                  @HeaderParam("Idempotency-Key") String idempotencyKey) {
        try {
            if (hasKey(idempotencyKey)) {
                vehicleInformationService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            VehicleInformation saved = vehicleInformationService.createVehicleInformation(request);
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Create vehicle failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{vehicleId}")
    @RunOnVirtualThread
    public Response updateVehicle(@PathParam("vehicleId") Long vehicleId,
                                  VehicleInformation request,
                                  @HeaderParam("Idempotency-Key") String idempotencyKey) {
        try {
            request.setVehicleId(vehicleId);
            if (hasKey(idempotencyKey)) {
                vehicleInformationService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            VehicleInformation updated = vehicleInformationService.updateVehicleInformation(request);
            return Response.ok(updated).build();
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Update vehicle failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{vehicleId}")
    @RunOnVirtualThread
    public Response deleteVehicle(@PathParam("vehicleId") Long vehicleId) {
        try {
            vehicleInformationService.deleteVehicleInformation(vehicleId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete vehicle failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/license/{licensePlate}")
    @RunOnVirtualThread
    public Response deleteVehicleByLicense(@PathParam("licensePlate") String licensePlate) {
        try {
            vehicleInformationService.deleteVehicleInformationByLicensePlate(licensePlate);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete vehicle by license failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{vehicleId}")
    @RunOnVirtualThread
    public Response getVehicle(@PathParam("vehicleId") Long vehicleId) {
        try {
            VehicleInformation vehicle = vehicleInformationService.getVehicleInformationById(vehicleId);
            return vehicle == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(vehicle).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get vehicle failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response listVehicles() {
        try {
            return Response.ok(vehicleInformationService.getAllVehicleInformation()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List vehicles failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/license")
    @RunOnVirtualThread
    public Response searchByLicense(@QueryParam("licensePlate") String licensePlate) {
        try {
            VehicleInformation vehicle = vehicleInformationService.getVehicleInformationByLicensePlate(licensePlate);
            return vehicle == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(vehicle).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by license failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/owner")
    @RunOnVirtualThread
    public Response searchByOwnerIdCard(@QueryParam("idCard") String idCard) {
        try {
            return Response.ok(vehicleInformationService.getVehicleInformationByIdCardNumber(idCard)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by id card failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/type")
    @RunOnVirtualThread
    public Response searchByType(@QueryParam("type") String type) {
        try {
            return Response.ok(vehicleInformationService.getVehicleInformationByType(type)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by type failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/owner/name")
    @RunOnVirtualThread
    public Response searchByOwnerName(@QueryParam("ownerName") String ownerName) {
        try {
            return Response.ok(vehicleInformationService.getVehicleInformationByOwnerName(ownerName)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by owner name failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/status")
    @RunOnVirtualThread
    public Response searchByStatus(@QueryParam("status") String status) {
        try {
            return Response.ok(vehicleInformationService.getVehicleInformationByStatus(status)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by status failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/general")
    @RunOnVirtualThread
    public Response searchVehicles(@QueryParam("keywords") String keywords,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(vehicleInformationService.searchVehicles(keywords, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "General vehicle search failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @POST
    @Path("/{vehicleId}/drivers")
    @RunOnVirtualThread
    public Response bindDriver(@PathParam("vehicleId") Long vehicleId,
                               DriverVehicle relation,
                               @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            relation.setVehicleId(vehicleId);
            if (useKey) {
                if (driverVehicleService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                driverVehicleService.checkAndInsertIdempotency(idempotencyKey, relation, "create");
            }
            DriverVehicle saved = driverVehicleService.createBinding(relation);
            if (useKey && saved.getId() != null) {
                driverVehicleService.markHistorySuccess(idempotencyKey, saved.getId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                driverVehicleService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create driver-vehicle binding failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{vehicleId}/drivers")
    @RunOnVirtualThread
    public Response listBindings(@PathParam("vehicleId") Long vehicleId,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(driverVehicleService.findByVehicleId(vehicleId, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List driver-vehicle binding failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/bindings/{bindingId}")
    @RunOnVirtualThread
    public Response deleteBinding(@PathParam("bindingId") Long bindingId) {
        try {
            driverVehicleService.deleteBinding(bindingId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete driver-vehicle binding failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/bindings/{bindingId}")
    @RunOnVirtualThread
    public Response updateBinding(@PathParam("bindingId") Long bindingId,
                                  DriverVehicle relation,
                                  @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            relation.setId(bindingId);
            if (useKey) {
                driverVehicleService.checkAndInsertIdempotency(idempotencyKey, relation, "update");
            }
            DriverVehicle updated = driverVehicleService.updateBinding(relation);
            if (useKey && updated.getId() != null) {
                driverVehicleService.markHistorySuccess(idempotencyKey, updated.getId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                driverVehicleService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update driver-vehicle binding failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/bindings/{bindingId}")
    @RunOnVirtualThread
    public Response getBinding(@PathParam("bindingId") Long bindingId) {
        try {
            DriverVehicle binding = driverVehicleService.findById(bindingId);
            return binding == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(binding).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get driver-vehicle binding failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/bindings")
    @RunOnVirtualThread
    public Response listBindingsOverview() {
        try {
            return Response.ok(driverVehicleService.findAll()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List driver-vehicle bindings failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/drivers/{driverId}/vehicles")
    @RunOnVirtualThread
    public Response listByDriver(@PathParam("driverId") Long driverId,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(driverVehicleService.findByDriverId(driverId, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List driver bindings failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/drivers/{driverId}/vehicles/primary")
    @RunOnVirtualThread
    public Response primaryBinding(@PathParam("driverId") Long driverId) {
        try {
            return Response.ok(driverVehicleService.findPrimaryBinding(driverId)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get primary binding failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/bindings/search/relationship")
    @RunOnVirtualThread
    public Response searchByRelationship(@QueryParam("relationship") String relationship,
                                         @QueryParam("page") Integer page,
                                         @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(driverVehicleService.searchByRelationship(relationship, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search bindings by relationship failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/license/global")
    @RunOnVirtualThread
    public Response globalPlateSuggestions(@QueryParam("prefix") String prefix,
                                           @QueryParam("size") Integer size) {
        try {
            int resolvedSize = size == null ? 10 : size;
            return Response.ok(vehicleInformationService.getVehicleInformationByLicensePlateGlobally(prefix, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch global plate suggestions failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/autocomplete/plates")
    @RunOnVirtualThread
    public Response plateAutocomplete(@QueryParam("prefix") String prefix,
                                      @QueryParam("size") Integer size,
                                      @QueryParam("idCard") String idCard) {
        try {
            int resolvedSize = size == null ? 10 : size;
            return Response.ok(vehicleInformationService.getLicensePlateAutocompleteSuggestions(prefix, resolvedSize, idCard)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch plate autocomplete failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/autocomplete/types")
    @RunOnVirtualThread
    public Response vehicleTypeAutocomplete(@QueryParam("idCard") String idCard,
                                            @QueryParam("prefix") String prefix,
                                            @QueryParam("size") Integer size) {
        try {
            int resolvedSize = size == null ? 10 : size;
            return Response.ok(vehicleInformationService.getVehicleTypeAutocompleteSuggestions(idCard, prefix, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch vehicle type autocomplete failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/autocomplete/types/global")
    @RunOnVirtualThread
    public Response vehicleTypeAutocompleteGlobal(@QueryParam("prefix") String prefix,
                                                  @QueryParam("size") Integer size) {
        try {
            int resolvedSize = size == null ? 10 : size;
            return Response.ok(vehicleInformationService.getVehicleTypesByPrefixGlobally(prefix, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch global vehicle type autocomplete failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/exists/{licensePlate}")
    @RunOnVirtualThread
    public Response licenseExists(@PathParam("licensePlate") String licensePlate) {
        try {
            boolean exists = vehicleInformationService.isLicensePlateExists(licensePlate);
            return Response.ok(Map.of("exists", exists)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "License plate existence check failed", ex);
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
