package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.entity.DeductionRecord;
import com.tutict.finalassignmentbackend.entity.FineRecord;
import com.tutict.finalassignmentbackend.entity.OffenseRecord;
import com.tutict.finalassignmentbackend.entity.PaymentRecord;
import com.tutict.finalassignmentbackend.service.AppealRecordService;
import com.tutict.finalassignmentbackend.service.DeductionRecordService;
import com.tutict.finalassignmentbackend.service.FineRecordService;
import com.tutict.finalassignmentbackend.service.OffenseRecordService;
import com.tutict.finalassignmentbackend.service.PaymentRecordService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/violations")
@Tag(name = "Traffic Violations", description = "交通违法全流程聚合查询接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "APPEAL_REVIEWER", "FINANCE"})
public class TrafficViolationController {

    private static final Logger LOG = Logger.getLogger(TrafficViolationController.class.getName());

    private final OffenseRecordService offenseRecordService;
    private final FineRecordService fineRecordService;
    private final PaymentRecordService paymentRecordService;
    private final DeductionRecordService deductionRecordService;
    private final AppealRecordService appealRecordService;

    public TrafficViolationController(OffenseRecordService offenseRecordService,
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

    @GetMapping
    @Operation(summary = "查询全部交通违法记录")
    public ResponseEntity<List<OffenseRecord>> listViolations() {
        try {
            return ResponseEntity.ok(offenseRecordService.findAll());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List violations failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/{offenseId}")
    @Operation(summary = "查询单条交通违法全链路详情")
    public ResponseEntity<Map<String, Object>> violationDetails(@PathVariable Long offenseId) {
        try {
            OffenseRecord offense = offenseRecordService.findById(offenseId);
            if (offense == null) {
                return ResponseEntity.notFound().build();
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

            List<AppealRecord> appeals = appealRecordService.findByOffenseId(offenseId, 1, 20);
            payload.put("appeals", appeals);

            return ResponseEntity.ok(payload);
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Get violation details failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/status")
    @Operation(summary = "按处理状态筛选交通违法")
    public ResponseEntity<List<OffenseRecord>> violationByStatus(@RequestParam String processStatus,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByProcessStatus(processStatus, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Filter violations by status failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
