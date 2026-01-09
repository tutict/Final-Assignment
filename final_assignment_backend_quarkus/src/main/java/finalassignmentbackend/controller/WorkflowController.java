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
import finalassignmentbackend.service.AppealManagementService;
import finalassignmentbackend.service.OffenseRecordService;
import finalassignmentbackend.service.PaymentRecordService;
import finalassignmentbackend.service.statemachine.StateMachineService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/workflow")
@Produces(MediaType.APPLICATION_JSON)
@Tag(name = "Workflow Engine", description = "State machine driven workflow endpoints")
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
                                        @PathParam("event") PaymentEvent event) {
        PaymentRecord record = paymentRecordService.findById(paymentId);
        if (record == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        PaymentState currentState = resolvePaymentState(record.getPaymentStatus());
        PaymentState newState = stateMachineService.processPaymentState(paymentId, currentState, event);
        if (newState == currentState) {
            LOG.log(Level.WARNING, "Payment {0} event {1} rejected at state {2}",
                    new Object[]{paymentId, event, currentState});
            return Response.status(Response.Status.CONFLICT).entity(record).build();
        }
        PaymentRecord updated = paymentRecordService.updatePaymentStatus(paymentId, newState.getCode());
        return Response.ok(updated).build();
    }

    @POST
    @Path("/appeals/{appealId}/events/{event}")
    @RunOnVirtualThread
    public Response triggerAppealEvent(@PathParam("appealId") Long appealId,
                                       @PathParam("event") AppealProcessEvent event) {
        AppealRecord record = appealManagementService.getAppealById(appealId);
        if (record == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        AppealProcessState currentState = resolveAppealState(record.getProcessStatus());
        AppealProcessState newState = stateMachineService.processAppealState(appealId, currentState, event);
        if (newState == currentState) {
            LOG.log(Level.WARNING, "Appeal {0} event {1} rejected at state {2}",
                    new Object[]{appealId, event, currentState});
            return Response.status(Response.Status.CONFLICT).entity(record).build();
        }
        AppealRecord updated = appealManagementService.updateProcessStatus(appealId, newState);
        return Response.ok(updated).build();
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
