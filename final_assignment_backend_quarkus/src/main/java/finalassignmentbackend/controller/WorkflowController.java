package finalassignmentbackend.controller;

import finalassignmentbackend.config.statemachine.events.AppealProcessEvent;
import finalassignmentbackend.config.statemachine.events.OffenseProcessEvent;
import finalassignmentbackend.config.statemachine.events.PaymentEvent;
import finalassignmentbackend.config.statemachine.states.AppealProcessState;
import finalassignmentbackend.config.statemachine.states.OffenseProcessState;
import finalassignmentbackend.config.statemachine.states.PaymentState;
import finalassignmentbackend.entity.AppealRecord;
import finalassignmentbackend.entity.OffenseRecord;
import finalassignmentbackend.entity.PaymentRecord;
import finalassignmentbackend.reliability.IdempotencyConflictException;
import finalassignmentbackend.reliability.IdempotencyInProgressException;
import finalassignmentbackend.reliability.IdempotencyReplayException;
import finalassignmentbackend.reliability.ReliabilityMetrics;
import finalassignmentbackend.reliability.WorkflowEventLedger;
import finalassignmentbackend.service.appeal.AppealManagementService;
import finalassignmentbackend.service.offense.OffenseRecordService;
import finalassignmentbackend.service.payment.PaymentRecordService;
import finalassignmentbackend.service.statemachine.StateMachineService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/workflow")
@Produces(MediaType.APPLICATION_JSON)
@Tag(name = "Workflow Engine", description = "State machine driven workflow endpoints")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE"})
public class WorkflowController {

    private static final Logger LOG = Logger.getLogger(WorkflowController.class.getName());

    @Inject
    StateMachineService stateMachineService;

    @Inject
    OffenseRecordService offenseRecordService;

    @Inject
    PaymentRecordService paymentRecordService;

    @Inject
    AppealManagementService appealManagementService;

    @Inject
    WorkflowEventLedger workflowEventLedger;

    @Inject
    ReliabilityMetrics metrics;

    @POST
    @Path("/offenses/{offenseId}/events/{event}")
    @RunOnVirtualThread
    public Response triggerOffenseEvent(@PathParam("offenseId") Long offenseId,
                                        @PathParam("event") OffenseProcessEvent event) {
        OffenseRecord record = offenseRecordService.findById(offenseId);
        if (record == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        OffenseProcessState currentState = resolveOffenseState(record.getProcessStatus());
        OffenseProcessState newState = stateMachineService.processOffenseState(offenseId, currentState, event);
        if (newState == currentState) {
            LOG.log(Level.WARNING, "Offense {0} event {1} rejected at state {2}",
                    new Object[]{offenseId, event, currentState});
            return Response.status(Response.Status.CONFLICT).entity(record).build();
        }
        OffenseRecord updated = offenseRecordService.updateProcessStatus(offenseId, newState);
        return Response.ok(updated).build();
    }

    @POST
    @Path("/payments/{paymentId}/events/{event}")
    @RunOnVirtualThread
    public Response triggerPaymentEvent(@PathParam("paymentId") Long paymentId,
                                        @PathParam("event") PaymentEvent event,
                                        @HeaderParam("Idempotency-Key") String idempotencyKey) {
        if (isBlank(idempotencyKey)) {
            return missingKey();
        }
        PaymentRecord record = paymentRecordService.findById(paymentId);
        if (record == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        String eventName = event.name();
        try {
            workflowEventLedger.reserve(idempotencyKey, "PAYMENT_STATUS",
                    "/api/workflow/payments/" + paymentId + "/events/" + eventName, paymentId, eventName);
        } catch (IdempotencyReplayException ex) {
            return Response.status(208).build();
        } catch (IdempotencyConflictException ex) {
            if (metrics != null) {
                metrics.idempotencyConflict();
            }
            return Response.status(Response.Status.CONFLICT).build();
        } catch (IdempotencyInProgressException ex) {
            return Response.status(Response.Status.CONFLICT).header("Retry-After", "1").build();
        }
        PaymentState currentState = resolvePaymentState(record.getPaymentStatus());
        PaymentState newState = stateMachineService.processPaymentState(paymentId, currentState, event);
        if (newState == currentState) {
            LOG.log(Level.WARNING, "Payment {0} event {1} rejected at state {2}",
                    new Object[]{paymentId, event, currentState});
            workflowEventLedger.markFailed(idempotencyKey, "workflow transition rejected");
            return workflowConflict();
        }
        try {
            PaymentRecord updated = paymentRecordService.updatePaymentStatus(paymentId, newState.getCode());
            workflowEventLedger.markSuccess(idempotencyKey, paymentId);
            return Response.ok(updated).build();
        } catch (RuntimeException ex) {
            workflowEventLedger.markFailed(idempotencyKey, ex.getMessage());
            LOG.log(Level.WARNING, "Payment workflow update failed", ex);
            return Response.serverError().build();
        }
    }

    @POST
    @Path("/appeals/{appealId}/events/{event}")
    @RunOnVirtualThread
    public Response triggerAppealEvent(@PathParam("appealId") Long appealId,
                                       @PathParam("event") AppealProcessEvent event,
                                       @HeaderParam("Idempotency-Key") String idempotencyKey) {
        if (isBlank(idempotencyKey)) {
            return missingKey();
        }
        AppealRecord record = appealManagementService.getAppealById(appealId);
        if (record == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        String eventName = event.name();
        try {
            workflowEventLedger.reserve(idempotencyKey, "APPEAL_STATUS",
                    "/api/workflow/appeals/" + appealId + "/events/" + eventName, appealId, eventName);
        } catch (IdempotencyReplayException ex) {
            return Response.status(208).build();
        } catch (IdempotencyConflictException ex) {
            if (metrics != null) {
                metrics.idempotencyConflict();
            }
            return Response.status(Response.Status.CONFLICT).build();
        } catch (IdempotencyInProgressException ex) {
            return Response.status(Response.Status.CONFLICT).header("Retry-After", "1").build();
        }
        AppealProcessState currentState = resolveAppealState(record.getProcessStatus());
        AppealProcessState newState = stateMachineService.processAppealState(appealId, currentState, event);
        if (newState == currentState) {
            LOG.log(Level.WARNING, "Appeal {0} event {1} rejected at state {2}",
                    new Object[]{appealId, event, currentState});
            workflowEventLedger.markFailed(idempotencyKey, "workflow transition rejected");
            return workflowConflict();
        }
        try {
            AppealRecord updated = appealManagementService.updateProcessStatus(appealId, newState);
            workflowEventLedger.markSuccess(idempotencyKey, appealId);
            return Response.ok(updated).build();
        } catch (RuntimeException ex) {
            workflowEventLedger.markFailed(idempotencyKey, ex.getMessage());
            LOG.log(Level.WARNING, "Appeal workflow update failed", ex);
            return Response.serverError().build();
        }
    }

    private static Response missingKey() {
        return Response.status(Response.Status.BAD_REQUEST)
                .entity(Map.of("errorCode", "MISSING_HEADER", "message", "Missing required header: Idempotency-Key"))
                .build();
    }

    private static Response workflowConflict() {
        return Response.status(Response.Status.CONFLICT)
                .entity(Map.of("errorCode", "WORKFLOW_CONFLICT", "message", "该记录已被处理，请刷新页面查看最新状态"))
                .build();
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
