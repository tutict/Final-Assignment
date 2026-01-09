package finalassignmentbackend.controller;

import finalassignmentbackend.entity.AppealRecord;
import finalassignmentbackend.entity.DeductionRecord;
import finalassignmentbackend.entity.FineRecord;
import finalassignmentbackend.entity.OffenseRecord;
import finalassignmentbackend.entity.PaymentRecord;
import finalassignmentbackend.service.AppealManagementService;
import finalassignmentbackend.service.DeductionRecordService;
import finalassignmentbackend.service.FineRecordService;
import finalassignmentbackend.service.OffenseRecordService;
import finalassignmentbackend.service.PaymentRecordService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/violations")
@Produces(MediaType.APPLICATION_JSON)
@Tag(name = "Traffic Violations", description = "Traffic violation aggregation endpoints")
public class TrafficViolationController {

    private static final Logger LOG = Logger.getLogger(TrafficViolationController.class.getName());

    @Inject
    OffenseRecordService offenseRecordService;

    @Inject
    FineRecordService fineRecordService;

    @Inject
    PaymentRecordService paymentRecordService;

    @Inject
    DeductionRecordService deductionRecordService;

    @Inject
    AppealManagementService appealManagementService;

    @GET
    @RunOnVirtualThread
    public Response listViolations() {
        try {
            return Response.ok(offenseRecordService.findAll()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List violations failed", ex);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GET
    @Path("/{offenseId}")
    @RunOnVirtualThread
    public Response violationDetails(@PathParam("offenseId") Long offenseId) {
        try {
            OffenseRecord offense = offenseRecordService.findById(offenseId);
            if (offense == null) {
                return Response.status(Response.Status.NOT_FOUND).build();
            }
            Map<String, Object> payload = new HashMap<>();
            payload.put("offense", offense);

            List<FineRecord> fines = fineRecordService.findByOffenseId(offenseId, 1, 50);
            payload.put("fines", fines);

            List<PaymentRecord> payments = new ArrayList<>();
            for (FineRecord fine : fines) {
                if (fine.getFineId() != null) {
                    payments.addAll(paymentRecordService.findByFineId(fine.getFineId(), 1, 20));
                }
            }
            payload.put("payments", payments);

            List<DeductionRecord> deductions = deductionRecordService.findByOffenseId(offenseId, 1, 50);
            payload.put("deductions", deductions);

            List<AppealRecord> appeals = appealManagementService.findByOffenseId(offenseId, 1, 20);
            payload.put("appeals", appeals);

            return Response.ok(payload).build();
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Get violation details failed", ex);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GET
    @Path("/status")
    @RunOnVirtualThread
    public Response violationByStatus(@QueryParam("processStatus") String processStatus,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(offenseRecordService.searchByProcessStatus(processStatus, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Filter violations by status failed", ex);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }
}
