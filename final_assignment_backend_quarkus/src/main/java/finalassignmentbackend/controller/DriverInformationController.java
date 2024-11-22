package finalassignmentbackend.controller;

import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.DriverInformation;
import finalassignmentbackend.service.DriverInformationService;
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

@Path("/eventbus/drivers")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class DriverInformationController {

    @Inject
    DriverInformationService driverInformationService;

    @POST
    public Response createDriver(DriverInformation driverInformation) {
        driverInformationService.createDriver(driverInformation);
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{driverId}")
    public Response getDriverById(@PathParam("driverId") int driverId) {
        DriverInformation driverInformation = driverInformationService.getDriverById(driverId);
        if (driverInformation != null) {
            return Response.ok(driverInformation).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    public Response getAllDrivers() {
        List<DriverInformation> drivers = driverInformationService.getAllDrivers();
        return Response.ok(drivers).build();
    }

    @PUT
    @Path("/{driverId}")
    public Response updateDriver(@PathParam("driverId") int driverId, DriverInformation updatedDriverInformation) {
        DriverInformation existingDriverInformation = driverInformationService.getDriverById(driverId);
        if (existingDriverInformation != null) {
            updatedDriverInformation.setDriverId(driverId);
            driverInformationService.updateDriver(updatedDriverInformation);
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{driverId}")
    public Response deleteDriver(@PathParam("driverId") int driverId) {
        driverInformationService.deleteDriver(driverId);
        return Response.noContent().build();
    }

    @GET
    @Path("/idCardNumber/{idCardNumber}")
    public Response getDriversByIdCardNumber(@PathParam("idCardNumber") String idCardNumber) {
        List<DriverInformation> drivers = driverInformationService.getDriversByIdCardNumber(idCardNumber);
        return Response.ok(drivers).build();
    }

    @GET
    @Path("/driverLicenseNumber/{driverLicenseNumber}")
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
    public Response getDriversByName(@PathParam("name") String name) {
        List<DriverInformation> drivers = driverInformationService.getDriversByName(name);
        return Response.ok(drivers).build();
    }
}
