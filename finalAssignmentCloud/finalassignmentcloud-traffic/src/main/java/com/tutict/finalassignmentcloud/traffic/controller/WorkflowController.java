package com.tutict.finalassignmentcloud.traffic.controller;

import com.tutict.finalassignmentcloud.traffic.config.statemachine.events.AppealProcessEvent;
import com.tutict.finalassignmentcloud.traffic.config.statemachine.events.OffenseProcessEvent;
import com.tutict.finalassignmentcloud.traffic.config.statemachine.events.PaymentEvent;
import com.tutict.finalassignmentcloud.traffic.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentcloud.traffic.config.statemachine.states.OffenseProcessState;
import com.tutict.finalassignmentcloud.traffic.config.statemachine.states.PaymentState;
import com.tutict.finalassignmentcloud.entity.AppealRecord;
import com.tutict.finalassignmentcloud.entity.OffenseRecord;
import com.tutict.finalassignmentcloud.entity.PaymentRecord;
import com.tutict.finalassignmentcloud.traffic.reliability.IdempotencyConflictException;
import com.tutict.finalassignmentcloud.traffic.reliability.IdempotencyInProgressException;
import com.tutict.finalassignmentcloud.traffic.reliability.IdempotencyReplayException;
import com.tutict.finalassignmentcloud.traffic.reliability.TrafficReliabilityMetrics;
import com.tutict.finalassignmentcloud.traffic.reliability.WorkflowEventLedger;
import com.tutict.finalassignmentcloud.traffic.service.AppealRecordService;
import com.tutict.finalassignmentcloud.traffic.service.OffenseRecordService;
import com.tutict.finalassignmentcloud.traffic.service.PaymentRecordService;
import com.tutict.finalassignmentcloud.traffic.service.statemachine.StateMachineService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/workflow")
@Tag(name = "Workflow Engine", description = "基于状态机的业务流程控制接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE", "APPEAL_REVIEWER"})
public class WorkflowController {

    private static final Logger LOG = Logger.getLogger(WorkflowController.class.getName());

    private final StateMachineService stateMachineService;
    private final OffenseRecordService offenseRecordService;
    private final PaymentRecordService paymentRecordService;
    private final AppealRecordService appealRecordService;
    private final WorkflowEventLedger workflowEventLedger;
    private final TrafficReliabilityMetrics metrics;

    public WorkflowController(StateMachineService stateMachineService,
                              OffenseRecordService offenseRecordService,
                              PaymentRecordService paymentRecordService,
                              AppealRecordService appealRecordService,
                              WorkflowEventLedger workflowEventLedger,
                              TrafficReliabilityMetrics metrics) {
        this.stateMachineService = stateMachineService;
        this.offenseRecordService = offenseRecordService;
        this.paymentRecordService = paymentRecordService;
        this.appealRecordService = appealRecordService;
        this.workflowEventLedger = workflowEventLedger;
        this.metrics = metrics;
    }

    @PostMapping("/offenses/{offenseId}/events/{event}")
    @Operation(summary = "触发违法记录状态事件")
    public ResponseEntity<OffenseRecord> triggerOffenseEvent(@PathVariable Long offenseId,
                                                             @PathVariable OffenseProcessEvent event) {
        OffenseRecord record = offenseRecordService.findById(offenseId);
        if (record == null) {
            return ResponseEntity.notFound().build();
        }
        OffenseProcessState currentState = resolveOffenseState(record.getProcessStatus());
        OffenseProcessState newState = stateMachineService.processOffenseState(offenseId, currentState, event);
        if (newState == currentState) {
            LOG.log(Level.WARNING, "Offense {0} event {1} rejected at state {2}", new Object[]{offenseId, event, currentState});
            return ResponseEntity.status(HttpStatus.CONFLICT).body(record);
        }
        OffenseRecord updated = offenseRecordService.updateProcessStatus(offenseId, newState);
        return ResponseEntity.ok(updated);
    }

    @PostMapping("/payments/{paymentId}/events/{event}")
    @Operation(summary = "触发支付状态事件")
    public ResponseEntity<?> triggerPaymentEvent(@PathVariable Long paymentId,
                                                 @PathVariable PaymentEvent event,
                                                 @RequestHeader(value = "Idempotency-Key", required = false)
                                                 String idempotencyKey) {
        if (isBlank(idempotencyKey)) {
            return missingKey();
        }
        PaymentRecord record = paymentRecordService.findById(paymentId);
        if (record == null) {
            return ResponseEntity.notFound().build();
        }
        String eventName = event.name();
        try {
            workflowEventLedger.reserve(idempotencyKey, "PAYMENT_STATUS",
                    "/api/workflow/payments/" + paymentId + "/events/" + eventName, paymentId, eventName);
        } catch (IdempotencyReplayException ex) {
            return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
        } catch (IdempotencyConflictException ex) {
            metrics.idempotencyConflict();
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        } catch (IdempotencyInProgressException ex) {
            return ResponseEntity.status(HttpStatus.CONFLICT).header("Retry-After", "1").build();
        }
        PaymentState currentState = resolvePaymentState(record.getPaymentStatus());
        PaymentState newState = stateMachineService.processPaymentState(paymentId, currentState, event);
        if (newState == currentState) {
            LOG.log(Level.WARNING, "Payment {0} event {1} rejected at state {2}", new Object[]{paymentId, event, currentState});
            workflowEventLedger.markFailed(idempotencyKey, "workflow transition rejected");
            return workflowConflict();
        }
        try {
            PaymentRecord updated = paymentRecordService.updatePaymentStatus(paymentId, newState);
            workflowEventLedger.markSuccess(idempotencyKey, paymentId);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException ex) {
            workflowEventLedger.markFailed(idempotencyKey, ex.getMessage());
            LOG.log(Level.WARNING, "Payment workflow update failed", ex);
            return ResponseEntity.internalServerError().build();
        }
    }

    @PostMapping("/appeals/{appealId}/events/{event}")
    @Operation(summary = "触发申诉状态事件")
    public ResponseEntity<?> triggerAppealEvent(@PathVariable Long appealId,
                                                @PathVariable AppealProcessEvent event,
                                                @RequestHeader(value = "Idempotency-Key", required = false)
                                                String idempotencyKey) {
        if (isBlank(idempotencyKey)) {
            return missingKey();
        }
        AppealRecord record = appealRecordService.getAppealById(appealId);
        if (record == null) {
            return ResponseEntity.notFound().build();
        }
        String eventName = event.name();
        try {
            workflowEventLedger.reserve(idempotencyKey, "APPEAL_STATUS",
                    "/api/workflow/appeals/" + appealId + "/events/" + eventName, appealId, eventName);
        } catch (IdempotencyReplayException ex) {
            return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
        } catch (IdempotencyConflictException ex) {
            metrics.idempotencyConflict();
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        } catch (IdempotencyInProgressException ex) {
            return ResponseEntity.status(HttpStatus.CONFLICT).header("Retry-After", "1").build();
        }
        AppealProcessState currentState = resolveAppealState(record.getProcessStatus());
        AppealProcessState newState = stateMachineService.processAppealState(appealId, currentState, event);
        if (newState == currentState) {
            LOG.log(Level.WARNING, "Appeal {0} event {1} rejected at state {2}", new Object[]{appealId, event, currentState});
            workflowEventLedger.markFailed(idempotencyKey, "workflow transition rejected");
            return workflowConflict();
        }
        try {
            AppealRecord updated = appealRecordService.updateProcessStatus(appealId, newState);
            workflowEventLedger.markSuccess(idempotencyKey, appealId);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException ex) {
            workflowEventLedger.markFailed(idempotencyKey, ex.getMessage());
            LOG.log(Level.WARNING, "Appeal workflow update failed", ex);
            return ResponseEntity.internalServerError().build();
        }
    }

    private static ResponseEntity<Map<String, String>> missingKey() {
        return ResponseEntity.badRequest().body(Map.of(
                "errorCode", "MISSING_HEADER",
                "message", "Missing required header: Idempotency-Key"));
    }

    private static ResponseEntity<Map<String, String>> workflowConflict() {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                "errorCode", "WORKFLOW_CONFLICT",
                "message", "该记录已被处理，请刷新页面查看最新状态"));
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private OffenseProcessState resolveOffenseState(String code) {
        OffenseProcessState state = OffenseProcessState.fromCode(code);
        return state != null ? state : OffenseProcessState.UNPROCESSED;
    }

    private PaymentState resolvePaymentState(String code) {
        PaymentState state = PaymentState.fromCode(code);
        return state != null ? state : PaymentState.UNPAID;
    }

    private AppealProcessState resolveAppealState(String code) {
        AppealProcessState state = AppealProcessState.fromCode(code);
        return state != null ? state : AppealProcessState.UNPROCESSED;
    }
}
