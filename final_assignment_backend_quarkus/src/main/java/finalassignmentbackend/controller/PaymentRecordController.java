package finalassignmentbackend.controller;

import finalassignmentbackend.entity.PaymentRecord;
import finalassignmentbackend.service.PaymentRecordService;
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

import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/payments")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Payment Management", description = "Payment record management")
public class PaymentRecordController {

    private static final Logger LOG = Logger.getLogger(PaymentRecordController.class.getName());

    @Inject
    PaymentRecordService paymentRecordService;

    @POST
    @RunOnVirtualThread
    public Response createPayment(PaymentRecord request,
                                  @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (paymentRecordService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                paymentRecordService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            PaymentRecord saved = paymentRecordService.createPaymentRecord(request);
            if (useKey && saved.getPaymentId() != null) {
                paymentRecordService.markHistorySuccess(idempotencyKey, saved.getPaymentId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                paymentRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create payment record failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{paymentId}")
    @RunOnVirtualThread
    public Response updatePayment(@PathParam("paymentId") Long paymentId,
                                  PaymentRecord request,
                                  @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setPaymentId(paymentId);
            if (useKey) {
                paymentRecordService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            PaymentRecord updated = paymentRecordService.updatePaymentRecord(request);
            if (useKey && updated.getPaymentId() != null) {
                paymentRecordService.markHistorySuccess(idempotencyKey, updated.getPaymentId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                paymentRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update payment record failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{paymentId}")
    @RunOnVirtualThread
    public Response deletePayment(@PathParam("paymentId") Long paymentId) {
        try {
            paymentRecordService.deletePaymentRecord(paymentId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete payment record failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{paymentId}")
    @RunOnVirtualThread
    public Response getPayment(@PathParam("paymentId") Long paymentId) {
        PaymentRecord record = paymentRecordService.findById(paymentId);
        return record == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(record).build();
    }

    @GET
    @RunOnVirtualThread
    public Response listPayments() {
        return Response.ok(paymentRecordService.findAll()).build();
    }

    @GET
    @Path("/fine/{fineId}")
    @RunOnVirtualThread
    public Response findByFine(@PathParam("fineId") Long fineId,
                               @QueryParam("page") Integer page,
                               @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(paymentRecordService.findByFineId(fineId, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/payer")
    @RunOnVirtualThread
    public Response searchByPayer(@QueryParam("idCard") String idCard,
                                  @QueryParam("page") Integer page,
                                  @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(paymentRecordService.searchByPayerIdCard(idCard, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/status")
    @RunOnVirtualThread
    public Response searchByStatus(@QueryParam("status") String status,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(paymentRecordService.searchByPaymentStatus(status, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/transaction")
    @RunOnVirtualThread
    public Response searchByTransaction(@QueryParam("transactionId") String transactionId,
                                        @QueryParam("page") Integer page,
                                        @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(paymentRecordService.searchByTransactionId(transactionId, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/payment-number")
    @RunOnVirtualThread
    public Response searchByPaymentNumber(@QueryParam("paymentNumber") String paymentNumber,
                                          @QueryParam("page") Integer page,
                                          @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(paymentRecordService.searchByPaymentNumber(paymentNumber, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/payer-name")
    @RunOnVirtualThread
    public Response searchByPayerName(@QueryParam("payerName") String payerName,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(paymentRecordService.searchByPayerName(payerName, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/payment-method")
    @RunOnVirtualThread
    public Response searchByPaymentMethod(@QueryParam("paymentMethod") String paymentMethod,
                                          @QueryParam("page") Integer page,
                                          @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(paymentRecordService.searchByPaymentMethod(paymentMethod, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/payment-channel")
    @RunOnVirtualThread
    public Response searchByPaymentChannel(@QueryParam("paymentChannel") String paymentChannel,
                                           @QueryParam("page") Integer page,
                                           @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(paymentRecordService.searchByPaymentChannel(paymentChannel, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/time-range")
    @RunOnVirtualThread
    public Response searchByTimeRange(@QueryParam("startTime") String startTime,
                                      @QueryParam("endTime") String endTime,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(paymentRecordService.searchByPaymentTimeRange(startTime, endTime, resolvedPage, resolvedSize)).build();
    }

    @PUT
    @Path("/{paymentId}/status/{state}")
    @RunOnVirtualThread
    public Response updatePaymentStatus(@PathParam("paymentId") Long paymentId,
                                        @PathParam("state") String state) {
        try {
            PaymentRecord updated = paymentRecordService.updatePaymentStatus(paymentId, state);
            return Response.ok(updated).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Update payment status failed", ex);
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
