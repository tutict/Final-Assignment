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
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/view/offenses")
@Produces(MediaType.APPLICATION_JSON)
@Tag(name = "Offense Details View", description = "Offense details aggregation for views")
public class OffenseDetailsController {

    private static final Logger LOG = Logger.getLogger(OffenseDetailsController.class.getName());
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

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
    @Path("/{offenseId}")
    @RunOnVirtualThread
    public Response getDetails(@PathParam("offenseId") Long offenseId) {
        try {
            OffenseRecord offense = offenseRecordService.findById(offenseId);
            if (offense == null) {
                return Response.status(Response.Status.NOT_FOUND).build();
            }

            Map<String, Object> payload = new HashMap<>();
            payload.put("offense", offense);

            List<FineRecord> fines = fineRecordService.findByOffenseId(offenseId, 1, 20);
            payload.put("fines", fines);

            List<PaymentRecord> payments = new ArrayList<>();
            for (FineRecord fine : fines) {
                if (fine.getFineId() != null) {
                    payments.addAll(paymentRecordService.findByFineId(fine.getFineId(), 1, 10));
                }
            }
            payload.put("payments", payments);

            List<DeductionRecord> deductions = deductionRecordService.findByOffenseId(offenseId, 1, 20);
            payload.put("deductions", deductions);

            List<AppealRecord> appeals = appealManagementService.findByOffenseId(offenseId, 1, 20);
            payload.put("appeals", appeals);

            payload.put("timeline", buildTimeline(offense, fines, payments, appeals));
            return Response.ok(payload).build();
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Fetch offense view failed", ex);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    private List<Map<String, Object>> buildTimeline(OffenseRecord offense,
                                                    List<FineRecord> fines,
                                                    List<PaymentRecord> payments,
                                                    List<AppealRecord> appeals) {
        List<Map<String, Object>> timeline = new ArrayList<>();
        Map<String, Object> offenseNode = new HashMap<>();
        offenseNode.put("event", "Offense");
        offenseNode.put("timestamp", offense.getOffenseTime() != null ? offense.getOffenseTime().format(FORMATTER) : null);
        offenseNode.put("status", offense.getProcessStatus());
        timeline.add(offenseNode);

        for (FineRecord fine : fines) {
            Map<String, Object> fineNode = new HashMap<>();
            fineNode.put("event", "Fine");
            fineNode.put("timestamp", fine.getFineDate() != null ? fine.getFineDate().toString() : null);
            fineNode.put("status", fine.getPaymentStatus());
            timeline.add(fineNode);
        }

        for (PaymentRecord payment : payments) {
            Map<String, Object> paymentNode = new HashMap<>();
            paymentNode.put("event", "Payment");
            paymentNode.put("timestamp", payment.getPaymentTime() != null ? payment.getPaymentTime().format(FORMATTER) : null);
            paymentNode.put("status", payment.getPaymentStatus());
            timeline.add(paymentNode);
        }

        for (AppealRecord appeal : appeals) {
            Map<String, Object> appealNode = new HashMap<>();
            appealNode.put("event", "Appeal");
            appealNode.put("timestamp", appeal.getCreatedAt() != null ? appeal.getCreatedAt().format(FORMATTER) : null);
            appealNode.put("status", appeal.getProcessStatus());
            timeline.add(appealNode);
        }

        return timeline;
    }
}
