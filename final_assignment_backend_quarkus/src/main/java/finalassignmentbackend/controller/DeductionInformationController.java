package finalassignmentbackend.controller;

import finalassignmentbackend.entity.DeductionInformation;
import finalassignmentbackend.service.DeductionInformationService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.sql.Date;
import java.time.LocalDate;
import java.util.List;

@Path("/eventbus/deductions")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class DeductionInformationController {

    @Inject
    DeductionInformationService deductionInformationService;

    @POST
    public Response createDeduction(DeductionInformation deduction) {
        deductionInformationService.createDeduction(deduction);
        return Response.status(Response.Status.CREATED).build();
    }

    @PUT
    @Path("/{deductionId}")
    public Response getDeductionById(@PathParam("deductionId") int deductionId) {
        DeductionInformation deduction = deductionInformationService.getDeductionById(deductionId);
        if (deduction != null) {
            return Response.ok(deduction).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    public Response getAllDeductions() {
        List<DeductionInformation> deductions = deductionInformationService.getAllDeductions();
        return Response.ok(deductions).build();
    }

    @PUT
    @Path("/{deductionId}")
    public Response updateDeduction(@PathParam("deductionId") int deductionId, DeductionInformation updatedDeduction) {
        DeductionInformation existingDeduction = deductionInformationService.getDeductionById(deductionId);
        if (existingDeduction != null) {
            // Update the existing deduction
            existingDeduction.setRemarks(updatedDeduction.getRemarks());
            existingDeduction.setHandler(updatedDeduction.getHandler());
            existingDeduction.setDeductedPoints(updatedDeduction.getDeductedPoints());
            existingDeduction.setDeductionTime(updatedDeduction.getDeductionTime());
            existingDeduction.setApprover(updatedDeduction.getApprover());

            deductionInformationService.updateDeduction(updatedDeduction);
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{deductionId}")
    public Response deleteDeduction(@PathParam("deductionId") int deductionId) {
        deductionInformationService.deleteDeduction(deductionId);
        return Response.noContent().build();
    }

    @GET
    @Path("/handler/{handler}")
    public Response getDeductionsByHandler(@PathParam("handler") String handler) {
        List<DeductionInformation> deductions = deductionInformationService.getDeductionsByHandler(handler);
        return Response.ok(deductions).build();
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
            Date startTime = Date.valueOf(startDate);
            Date endTime = Date.valueOf(endDate);

            List<DeductionInformation> deductions = deductionInformationService.getDeductionsByByTimeRange(startTime, endTime);
            return Response.ok(deductions).build();
        } catch (Exception e) {
            return Response.status(Response.Status.BAD_REQUEST).entity("Invalid date format").build();
        }
    }
}