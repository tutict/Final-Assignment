package com.tutict.finalassignmentcloud.traffic.controller.view;

import com.tutict.finalassignmentcloud.entity.AppealRecord;
import com.tutict.finalassignmentcloud.entity.DeductionRecord;
import com.tutict.finalassignmentcloud.entity.FineRecord;
import com.tutict.finalassignmentcloud.entity.OffenseRecord;
import com.tutict.finalassignmentcloud.entity.PaymentRecord;
import com.tutict.finalassignmentcloud.traffic.service.AppealRecordService;
import com.tutict.finalassignmentcloud.traffic.service.DeductionRecordService;
import com.tutict.finalassignmentcloud.traffic.service.FineRecordService;
import com.tutict.finalassignmentcloud.traffic.service.OffenseRecordService;
import com.tutict.finalassignmentcloud.traffic.service.PaymentRecordService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/view/offenses")
@Tag(name = "Offense Details View", description = "面向前端的违法详情聚合视图接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "APPEAL_REVIEWER", "FINANCE"})
public class OffenseDetailsController {

    private static final Logger LOG = Logger.getLogger(OffenseDetailsController.class.getName());
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final OffenseRecordService offenseRecordService;
    private final FineRecordService fineRecordService;
    private final PaymentRecordService paymentRecordService;
    private final DeductionRecordService deductionRecordService;
    private final AppealRecordService appealRecordService;

    public OffenseDetailsController(OffenseRecordService offenseRecordService,
                                    FineRecordService fineRecordService,
                                    PaymentRecordService paymentRecordService,
                                    DeductionRecordService deductionRecordService,
                                    AppealRecordService appealRecordService) {
        this.offenseRecordService = offenseRecordService;
        this.fineRecordService = fineRecordService;
        this.paymentRecordService = paymentRecordService;
        this.deductionRecordService = deductionRecordService;
        this.appealRecordService = appealRecordService;
    }

    @GetMapping("/{offenseId}")
    @Operation(summary = "获取面向看板的违法详情")
    public ResponseEntity<Map<String, Object>> getDetails(@PathVariable Long offenseId) {
        try {
            OffenseRecord offense = offenseRecordService.findById(offenseId);
            if (offense == null) {
                return ResponseEntity.notFound().build();
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

            List<AppealRecord> appeals = appealRecordService.findByOffenseId(offenseId, 1, 20);
            payload.put("appeals", appeals);

            payload.put("timeline", buildTimeline(offense, fines, payments, appeals));

            return ResponseEntity.ok(payload);
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Fetch offense view failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    private List<Map<String, Object>> buildTimeline(OffenseRecord offense,
                                                    List<FineRecord> fines,
                                                    List<PaymentRecord> payments,
                                                    List<AppealRecord> appeals) {
        List<Map<String, Object>> timeline = new ArrayList<>();
        Map<String, Object> offenseNode = new HashMap<>();
        offenseNode.put("event", "违法记录");
        offenseNode.put("timestamp", offense.getOffenseTime() != null ? offense.getOffenseTime().format(FORMATTER) : null);
        offenseNode.put("status", offense.getProcessStatus());
        timeline.add(offenseNode);

        for (FineRecord fine : fines) {
            Map<String, Object> fineNode = new HashMap<>();
            fineNode.put("event", "罚款处理");
            fineNode.put("timestamp", fine.getFineDate() != null ? fine.getFineDate().toString() : null);
            fineNode.put("status", fine.getPaymentStatus());
            timeline.add(fineNode);
        }

        for (PaymentRecord payment : payments) {
            Map<String, Object> paymentNode = new HashMap<>();
            paymentNode.put("event", "缴费");
            paymentNode.put("timestamp", payment.getPaymentTime() != null ? payment.getPaymentTime().format(FORMATTER) : null);
            paymentNode.put("status", payment.getPaymentStatus());
            timeline.add(paymentNode);
        }

        for (AppealRecord appeal : appeals) {
            Map<String, Object> appealNode = new HashMap<>();
            appealNode.put("event", "申诉");
            appealNode.put("timestamp", appeal.getCreatedAt() != null ? appeal.getCreatedAt().format(FORMATTER) : null);
            appealNode.put("status", appeal.getProcessStatus());
            timeline.add(appealNode);
        }

        return timeline;
    }
}
