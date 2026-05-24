package com.tutict.finalassignmentbackend.controller.business;

import com.tutict.finalassignmentbackend.config.statemachine.events.AppealProcessEvent;
import com.tutict.finalassignmentbackend.config.statemachine.events.OffenseProcessEvent;
import com.tutict.finalassignmentbackend.config.statemachine.events.PaymentEvent;
import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.config.statemachine.states.OffenseProcessState;
import com.tutict.finalassignmentbackend.config.statemachine.states.PaymentState;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;
import com.tutict.finalassignmentbackend.entity.payment.PaymentRecord;
import com.tutict.finalassignmentbackend.payment.exception.PaymentDuplicateRequestException;
import com.tutict.finalassignmentbackend.payment.exception.PaymentOptimisticLockException;
import com.tutict.finalassignmentbackend.service.appeal.AppealRecordService;
import com.tutict.finalassignmentbackend.service.offense.OffenseRecordService;
import com.tutict.finalassignmentbackend.service.payment.PaymentRecordService;
import com.tutict.finalassignmentbackend.service.statemachine.StateMachineService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import java.util.logging.Level;
import java.util.logging.Logger;

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

    public WorkflowController(StateMachineService stateMachineService,
                              OffenseRecordService offenseRecordService,
                              PaymentRecordService paymentRecordService,
                              AppealRecordService appealRecordService) {
        this.stateMachineService = stateMachineService;
        this.offenseRecordService = offenseRecordService;
        this.paymentRecordService = paymentRecordService;
        this.appealRecordService = appealRecordService;
    }

    @PostMapping("/offenses/{offenseId}/events/{event}")
    @Operation(summary = "触发违法记录状态事件")
    public ResponseEntity<?> triggerOffenseEvent(@PathVariable Long offenseId,
                                                 @PathVariable OffenseProcessEvent event) {
        OffenseRecord record = offenseRecordService.findById(offenseId);
        if (record == null) {
            return ResponseEntity.notFound().build();
        }
        OffenseProcessState currentState = resolveOffenseState(record.getProcessStatus());
        OffenseProcessState newState = stateMachineService.processOffenseState(offenseId, currentState, event);
        if (newState == currentState) {
            LOG.log(Level.WARNING, "Offense {0} event {1} rejected at state {2}", new Object[]{offenseId, event, currentState});
            return workflowConflict();
        }
        OffenseRecord updated = offenseRecordService.updateProcessStatus(offenseId, newState);
        return ResponseEntity.ok(updated);
    }

    @PostMapping("/payments/{paymentId}/events/{event}")
    @Operation(summary = "触发支付状态事件")
    public ResponseEntity<?> triggerPaymentEvent(@PathVariable Long paymentId,
                                                 @PathVariable PaymentEvent event,
                                                 @RequestHeader(value = "Idempotency-Key", required = true)
                                                 String idempotencyKey) {
        PaymentRecord record = paymentRecordService.findById(paymentId);
        if (record == null) {
            return ResponseEntity.notFound().build();
        }
        if (paymentRecordService.isDuplicateIdempotencyKey(idempotencyKey)) {
            return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).body(ApiResponse.ok(null));
        }
        PaymentState currentState = resolvePaymentState(record.getPaymentStatus());
        PaymentState newState = stateMachineService.processPaymentState(paymentId, currentState, event);
        if (newState == currentState) {
            LOG.log(Level.WARNING, "Payment {0} event {1} rejected at state {2}", new Object[]{paymentId, event, currentState});
            return workflowConflict();
        }
        try {
            PaymentRecord updated = paymentRecordService.updatePaymentStatus(paymentId, newState, idempotencyKey);
            return ResponseEntity.ok(updated);
        } catch (PaymentDuplicateRequestException ex) {
            return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).body(ApiResponse.ok(null));
        } catch (PaymentOptimisticLockException ex) {
            return workflowConflict();
        }
    }

    @PostMapping("/appeals/{appealId}/events/{event}")
    @Operation(summary = "触发申诉状态事件")
    public ResponseEntity<?> triggerAppealEvent(@PathVariable Long appealId,
                                                @PathVariable AppealProcessEvent event) {
        AppealRecord record = appealRecordService.getAppealById(appealId);
        if (record == null) {
            return ResponseEntity.notFound().build();
        }
        AppealProcessState currentState = resolveAppealState(record.getProcessStatus());
        AppealProcessState newState = stateMachineService.processAppealState(appealId, currentState, event);
        if (newState == currentState) {
            LOG.log(Level.WARNING, "Appeal {0} event {1} rejected at state {2}", new Object[]{appealId, event, currentState});
            return workflowConflict();
        }
        AppealRecord updated = appealRecordService.updateProcessStatus(appealId, newState);
        return ResponseEntity.ok(updated);
    }

    private OffenseProcessState resolveOffenseState(String code) {
        OffenseProcessState state = OffenseProcessState.fromCode(code);
        return state != null ? state : OffenseProcessState.UNPROCESSED;
    }

    private ResponseEntity<ApiResponse<Void>> workflowConflict() {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiResponse.error("WORKFLOW_CONFLICT", "该记录已被处理，请刷新页面查看最新状态"));
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
