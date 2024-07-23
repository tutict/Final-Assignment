package finalassignmentbackend.controller;


import finalassignmentbackend.entity.OffenseInformation;
import finalassignmentbackend.service.OffenseInformationService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.time.LocalDate;
import java.util.List;

@Path("/eventbus/offenses")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class OffenseInformationController {

    @Inject
    OffenseInformationService offenseInformationService;

    @POST
    public Response createOffense(OffenseInformation offenseInformation) {
        offenseInformationService.createOffense(offenseInformation);
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{offenseId}")
    public Response getOffenseByOffenseId(@PathParam("offenseId") int offenseId) {
        OffenseInformation offenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
        if (offenseInformation != null) {
            return Response.ok(offenseInformation).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    public Response getOffensesInformation() {
        List<OffenseInformation> offensesInformation = offenseInformationService.getOffensesInformation();
        return Response.ok(offensesInformation).build();
    }

    @PUT
    @Path("/{offenseId}")
    public Response updateOffense(@PathParam("offenseId") int offenseId, OffenseInformation updatedOffenseInformation) {
        OffenseInformation existingOffenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
        if (existingOffenseInformation != null) {
            updatedOffenseInformation.setOffenseId(offenseId);
            offenseInformationService.updateOffense(updatedOffenseInformation);
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{offenseId}")
    public Response deleteOffense(@PathParam("offenseId") int offenseId) {
        offenseInformationService.deleteOffense(offenseId);
        return Response.noContent().build();
    }


    @GET
    @Path("/timeRange")
    public Response getDeductionsByTimeRange(
            @QueryParam("startTime") @DefaultValue("1970-01-01") String startTimeStr,
            @QueryParam("endTime") @DefaultValue("2100-12-31") String endTimeStr) {
        try {
            LocalDate startDate = LocalDate.parse(startTimeStr);
            LocalDate endDate = LocalDate.parse(endTimeStr);

            // Convert LocalDate to java.util.Date
            java.sql.Date startTime = java.sql.Date.valueOf(startDate);
            java.sql.Date endTime = java.sql.Date.valueOf(endDate);

            List<OffenseInformation> offenses = offenseInformationService.getOffensesByTimeRange(startTime, endTime);
            return Response.ok(offenses).build();
        } catch (Exception e) {
            return Response.status(Response.Status.BAD_REQUEST).entity("Invalid date format").build();
        }
    }


    @GET
    @Path("/processState/{processState}")
    public Response getOffensesByProcessState(@PathParam("processState") String processState) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByProcessState(processState);
        return Response.ok(offenses).build();
    }

    @GET
    @Path("/driverName/{driverName}")
    public Response getOffensesByDriverName(@PathParam("driverName") String driverName) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByDriverName(driverName);
        return Response.ok(offenses).build();
    }

    @GET
    @Path("/licensePlate/{licensePlate}")
    public Response getOffensesByLicensePlate(@PathParam("licensePlate") String licensePlate) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByLicensePlate(licensePlate);
        return Response.ok(offenses).build();
    }
}