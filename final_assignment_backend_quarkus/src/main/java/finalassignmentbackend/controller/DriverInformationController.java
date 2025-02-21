package finalassignmentbackend.controller;

import finalassignmentbackend.entity.DriverInformation;
import finalassignmentbackend.service.DriverInformationService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;

@Path("/api/drivers")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Driver Information", description = "Driver Information Controller for managing drivers")
public class DriverInformationController {

    @Inject
    DriverInformationService driverInformationService;

    @POST
    @RunOnVirtualThread
    public Response createDriver(DriverInformation driverInformation, @QueryParam("idempotencyKey") String idempotencyKey) {
        driverInformationService.checkAndInsertIdempotency(idempotencyKey, driverInformation, "create");
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{driverId}")
    @RunOnVirtualThread
    public Response getDriverById(@PathParam("driverId") int driverId) {
        DriverInformation driverInformation = driverInformationService.getDriverById(driverId);
        if (driverInformation != null) {
            return Response.ok(driverInformation).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response getAllDrivers() {
        List<DriverInformation> drivers = driverInformationService.getAllDrivers();
        return Response.ok(drivers).build();
    }

    @PUT
    @Path("/{driverId}")
    @RunOnVirtualThread
    public Response updateDriver(@PathParam("driverId") int driverId, DriverInformation updatedDriverInformation, @QueryParam("idempotencyKey") String idempotencyKey) {
        DriverInformation existingDriverInformation = driverInformationService.getDriverById(driverId);
        if (existingDriverInformation != null) {
            updatedDriverInformation.setDriverId(driverId);
            driverInformationService.checkAndInsertIdempotency(idempotencyKey, updatedDriverInformation, "update");
            return Response.ok(Response.Status.OK).entity(updatedDriverInformation).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{driverId}")
    @RunOnVirtualThread
    public Response deleteDriver(@PathParam("driverId") int driverId) {
        driverInformationService.deleteDriver(driverId);
        return Response.noContent().build();
    }

    @GET
    @Path("/idCardNumber/{idCardNumber}")
    @RunOnVirtualThread
    public Response getDriversByIdCardNumber(@PathParam("idCardNumber") String idCardNumber) {
        List<DriverInformation> drivers = driverInformationService.getDriversByIdCardNumber(idCardNumber);
        return Response.ok(drivers).build();
    }

    @GET
    @Path("/driverLicenseNumber/{driverLicenseNumber}")
    @RunOnVirtualThread
    public Response getDriverByDriverLicenseNumber(@PathParam("driverLicenseNumber") String driverLicenseNumber) {
        DriverInformation driverInformation = driverInformationService.getDriverByDriverLicenseNumber(driverLicenseNumber);
        if (driverInformation != null) {
            return Response.ok(driverInformation).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("/name/{name}")
    @RunOnVirtualThread
    public Response getDriversByName(@PathParam("name") String name) {
        List<DriverInformation> drivers = driverInformationService.getDriversByName(name);
        return Response.ok(drivers).build();
    }
}
