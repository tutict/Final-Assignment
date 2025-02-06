package finalassignmentbackend.controller;

import finalassignmentbackend.entity.DeductionInformation;
import finalassignmentbackend.service.DeductionInformationService;
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
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.Date;
import java.util.List;

@Path("/api/deductions")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Deduction Information", description = "Deduction Information Controller for managing deductions")
public class DeductionInformationController {

    @Inject
    DeductionInformationService deductionInformationService;

    @POST
    @RunOnVirtualThread
    public Response createDeduction(DeductionInformation deduction, String idempotencyKey) {
        deductionInformationService.checkAndInsertIdempotency(idempotencyKey, deduction, "create");
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{deductionId}")
    @RunOnVirtualThread
    public Response getDeductionById(@PathParam("deductionId") int deductionId) {
        DeductionInformation deduction = deductionInformationService.getDeductionById(deductionId);
        if (deduction != null) {
            return Response.ok(deduction).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response getAllDeductions() {
        List<DeductionInformation> deductions = deductionInformationService.getAllDeductions();
        return Response.ok(deductions).build();
    }

    @PUT
    @Path("/{deductionId}")
    @RunOnVirtualThread
    public Response updateDeduction(@PathParam("deductionId") int deductionId, DeductionInformation updatedDeduction, String idempotencyKey) {
        DeductionInformation existingDeduction = deductionInformationService.getDeductionById(deductionId);
        if (existingDeduction != null) {
            existingDeduction.setRemarks(updatedDeduction.getRemarks());
            existingDeduction.setHandler(updatedDeduction.getHandler());
            existingDeduction.setDeductedPoints(updatedDeduction.getDeductedPoints());
            existingDeduction.setDeductionTime(updatedDeduction.getDeductionTime());
            existingDeduction.setApprover(updatedDeduction.getApprover());

            deductionInformationService.checkAndInsertIdempotency(idempotencyKey, existingDeduction, "update");
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{deductionId}")
    @RunOnVirtualThread
    public Response deleteDeduction(@PathParam("deductionId") int deductionId) {
        deductionInformationService.deleteDeduction(deductionId);
        return Response.noContent().build();
    }

    @GET
    @Path("/handler/{handler}")
    @RunOnVirtualThread
    public Response getDeductionsByHandler(@PathParam("handler") String handler) {
        List<DeductionInformation> deductions = deductionInformationService.getDeductionsByHandler(handler);
        return Response.ok(deductions).build();
    }

    @GET
    @Path("/timeRange")
    @RunOnVirtualThread
    public Response getDeductionsByTimeRange(@QueryParam("startTime") Date startTime, @QueryParam("endTime") Date endTime) {
        List<DeductionInformation> deductions = deductionInformationService.getDeductionsByTimeRange(startTime, endTime);
        return Response.ok(deductions).build();
    }
}
