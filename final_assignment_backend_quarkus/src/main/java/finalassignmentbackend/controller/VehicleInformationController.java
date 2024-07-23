package finalassignmentbackend.controller;


import finalassignmentbackend.entity.VehicleInformation;
import finalassignmentbackend.service.VehicleInformationService;
import jakarta.inject.Inject;
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

@Path("/eventbus/vehicles")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class VehicleInformationController {

    @Inject
    VehicleInformationService vehicleInformationService;

    // Create a new vehicle
    @POST
    public Response createVehicleInformation(VehicleInformation vehicleInformation) {
        vehicleInformationService.createVehicleInformation(vehicleInformation);
        return Response.status(Response.Status.CREATED).build();
    }

    // Get a vehicle by ID
    @GET
    @Path("/{vehicleId}")
    public Response getVehicleInformationById(@PathParam("vehicleId") int vehicleId) {
        VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationById(vehicleId);
        if (vehicleInformation != null) {
            return Response.ok(vehicleInformation).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    // Get a vehicle by license plate
    @GET
    @Path("/license-plate/{licensePlate}")
    public Response getVehicleInformationByLicensePlate(@PathParam("licensePlate") String licensePlate) {
        VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationByLicensePlate(licensePlate);
        if (vehicleInformation != null) {
            return Response.ok(vehicleInformation).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    // Get all vehicles
    @GET
    public Response getAllVehicleInformation() {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getAllVehicleInformation();
        return Response.ok(vehicleInformationList).build();
    }

    // Get a vehicle by type
    @GET
    @Path("/type/{vehicleType}")
    public Response getVehicleInformationByType(@PathParam("vehicleType") String vehicleType) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByType(vehicleType);
        return Response.ok(vehicleInformationList).build();
    }

    // Get a vehicle by owner name
    @GET
    @Path("/owner/{ownerName}")
    public Response getVehicleInformationByOwnerName(@PathParam("ownerName") String ownerName) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByOwnerName(ownerName);
        return Response.ok(vehicleInformationList).build();
    }

    // Get a vehicle by status
    @GET
    @Path("/status/{currentStatus}")
    public Response getVehicleInformationByStatus(@PathParam("currentStatus") String currentStatus) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByStatus(currentStatus);
        return Response.ok(vehicleInformationList).build();
    }

    // Update a vehicle
    @PUT
    @Path("/{vehicleId}")
    public Response updateVehicleInformation(@PathParam("vehicleId") int vehicleId, VehicleInformation vehicleInformation) {
        vehicleInformation.setVehicleId(vehicleId);
        vehicleInformationService.updateVehicleInformation(vehicleInformation);
        return Response.ok().build();
    }

    // Delete a vehicle by ID
    @DELETE
    @Path("/{vehicleId}")
    public Response deleteVehicleInformation(@PathParam("vehicleId") int vehicleId) {
        vehicleInformationService.deleteVehicleInformation(vehicleId);
        return Response.noContent().build();
    }

    // Delete a vehicle by license plate
    @DELETE
    @Path("/license-plate/{licensePlate}")
    public Response deleteVehicleInformationByLicensePlate(@PathParam("licensePlate") String licensePlate) {
        vehicleInformationService.deleteVehicleInformationByLicensePlate(licensePlate);
        return Response.noContent().build();
    }

    // Check if a vehicle exists
    @GET
    @Path("/exists/{licensePlate}")
    public Response isLicensePlateExists(@PathParam("licensePlate") String licensePlate) {
        boolean exists = vehicleInformationService.isLicensePlateExists(licensePlate);
        return Response.ok(exists).build();
    }
}

