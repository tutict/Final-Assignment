package finalassignmentbackend.controller;

import finalassignmentbackend.entity.FineInformation;
import finalassignmentbackend.service.FineInformationService;
import io.smallrye.common.annotation.RunOnVirtualThread;
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

import java.util.Date;
import java.util.List;

@Path("/api/fines")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class FineInformationController {

    @Inject
    FineInformationService fineInformationService;

    @POST
    @RunOnVirtualThread
    public Response createFine(FineInformation fineInformation, String idempotencyKey) {
        fineInformationService.checkAndInsertIdempotency(idempotencyKey, fineInformation, "create");
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{fineId}")
    @RunOnVirtualThread
    public Response getFineById(@PathParam("fineId") int fineId) {
        FineInformation fineInformation = fineInformationService.getFineById(fineId);
        if (fineInformation != null) {
            return Response.ok(fineInformation).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response getAllFines() {
        List<FineInformation> fines = fineInformationService.getAllFines();
        return Response.ok(fines).build();
    }

    @PUT
    @Path("/{fineId}")
    @RunOnVirtualThread
    public Response updateFine(@PathParam("fineId") int fineId, FineInformation updatedFineInformation, String idempotencyKey) {
        FineInformation existingFineInformation = fineInformationService.getFineById(fineId);
        if (existingFineInformation != null) {
            updatedFineInformation.setFineId(fineId);
            fineInformationService.checkAndInsertIdempotency(idempotencyKey, updatedFineInformation, "update");
            return Response.ok(Response.Status.OK).entity(updatedFineInformation).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{fineId}")
    @RunOnVirtualThread
    public Response deleteFine(@PathParam("fineId") int fineId) {
        fineInformationService.deleteFine(fineId);
        return Response.noContent().build();
    }

    @GET
    @Path("/payee/{payee}")
    @RunOnVirtualThread
    public Response getFinesByPayee(@PathParam("payee") String payee) {
        List<FineInformation> fines = fineInformationService.getFinesByPayee(payee);
        return Response.ok(fines).build();
    }

    @GET
    @Path("/timeRange")
    @RunOnVirtualThread
    public Response getFinesByTimeRange(@QueryParam("startTime") @DefaultValue("1970-01-01") Date startTime,
                                        @QueryParam("endTime") @DefaultValue("2100-01-01") Date endTime) {
        List<FineInformation> fines = fineInformationService.getFinesByTimeRange(startTime, endTime);
        return Response.ok(fines).build();
    }

    @GET
    @Path("/receiptNumber/{receiptNumber}")
    @RunOnVirtualThread
    public Response getFineByReceiptNumber(@PathParam("receiptNumber") String receiptNumber) {
        FineInformation fineInformation = fineInformationService.getFineByReceiptNumber(receiptNumber);
        if (fineInformation != null) {
            return Response.ok(fineInformation).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }
}
