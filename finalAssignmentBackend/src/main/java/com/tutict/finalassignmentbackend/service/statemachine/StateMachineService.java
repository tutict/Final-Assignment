package com.tutict.finalassignmentbackend.service.statemachine;

import com.tutict.finalassignmentbackend.config.statemachine.events.AppealProcessEvent;
import com.tutict.finalassignmentbackend.config.statemachine.events.OffenseProcessEvent;
import com.tutict.finalassignmentbackend.config.statemachine.events.PaymentEvent;
import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.config.statemachine.states.OffenseProcessState;
import com.tutict.finalassignmentbackend.config.statemachine.states.PaymentState;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.statemachine.StateMachine;
import org.springframework.statemachine.StateMachineContext;
import org.springframework.statemachine.config.StateMachineFactory;
import org.springframework.statemachine.support.DefaultStateMachineContext;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class StateMachineService {

    private static final Logger LOG = Logger.getLogger(StateMachineService.class.getName());

    private final StateMachineFactory<OffenseProcessState, OffenseProcessEvent> offenseProcessStateMachineFactory;
    private final StateMachineFactory<PaymentState, PaymentEvent> paymentStateMachineFactory;
    private final StateMachineFactory<AppealProcessState, AppealProcessEvent> appealProcessStateMachineFactory;

    public StateMachineService(
            @Qualifier("offenseProcessStateMachineFactory")
            StateMachineFactory<OffenseProcessState, OffenseProcessEvent> offenseProcessStateMachineFactory,
            @Qualifier("paymentStateMachineFactory")
            StateMachineFactory<PaymentState, PaymentEvent> paymentStateMachineFactory,
            @Qualifier("appealProcessStateMachineFactory")
            StateMachineFactory<AppealProcessState, AppealProcessEvent> appealProcessStateMachineFactory
    ) {
        this.offenseProcessStateMachineFactory = offenseProcessStateMachineFactory;
        this.paymentStateMachineFactory = paymentStateMachineFactory;
        this.appealProcessStateMachineFactory = appealProcessStateMachineFactory;
    }

    public OffenseProcessState processOffenseState(
            Long offenseId,
            OffenseProcessState currentState,
            OffenseProcessEvent event
    ) {
        try {
            StateMachine<OffenseProcessState, OffenseProcessEvent> stateMachine =
                    offenseProcessStateMachineFactory.getStateMachine();
            stateMachine.getStateMachineAccessor().doWithAllRegions(access ->
                    access.resetStateMachineReactively(buildContext(currentState)).block(Duration.ofSeconds(10))
            );

            boolean result = stateMachine.sendEvent(event);
            if (result) {
                OffenseProcessState newState = stateMachine.getState().getId();
                LOG.log(Level.INFO, "Offense {0} workflow transitioned: {1} -> {2} by {3}",
                        new Object[]{offenseId, currentState, newState, event});
                return newState;
            }
            LOG.log(Level.WARNING, "Offense {0} workflow transition rejected: {1} by {2}",
                    new Object[]{offenseId, currentState, event});
            return currentState;
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Failed to process offense workflow event: " + e.getMessage(), e);
            return currentState;
        }
    }

    public PaymentState processPaymentState(
            Long fineId,
            PaymentState currentState,
            PaymentEvent event
    ) {
        try {
            StateMachine<PaymentState, PaymentEvent> stateMachine =
                    paymentStateMachineFactory.getStateMachine();
            stateMachine.getStateMachineAccessor().doWithAllRegions(access ->
                    access.resetStateMachineReactively(buildContext(currentState)).block(Duration.ofSeconds(10))
            );

            boolean result = stateMachine.sendEvent(event);
            if (result) {
                PaymentState newState = stateMachine.getState().getId();
                LOG.log(Level.INFO, "Payment {0} workflow transitioned: {1} -> {2} by {3}",
                        new Object[]{fineId, currentState, newState, event});
                return newState;
            }
            LOG.log(Level.WARNING, "Payment {0} workflow transition rejected: {1} by {2}",
                    new Object[]{fineId, currentState, event});
            return currentState;
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Failed to process payment workflow event: " + e.getMessage(), e);
            return currentState;
        }
    }

    public AppealProcessState processAppealState(
            Long appealId,
            AppealProcessState currentState,
            AppealProcessEvent event
    ) {
        try {
            StateMachine<AppealProcessState, AppealProcessEvent> stateMachine =
                    appealProcessStateMachineFactory.getStateMachine();
            stateMachine.getStateMachineAccessor().doWithAllRegions(access ->
                    access.resetStateMachineReactively(buildContext(currentState)).block(Duration.ofSeconds(10))
            );

            boolean result = stateMachine.sendEvent(event);
            if (result) {
                AppealProcessState newState = stateMachine.getState().getId();
                LOG.log(Level.INFO, "Appeal {0} workflow transitioned: {1} -> {2} by {3}",
                        new Object[]{appealId, currentState, newState, event});
                return newState;
            }
            LOG.log(Level.WARNING, "Appeal {0} workflow transition rejected: {1} by {2}",
                    new Object[]{appealId, currentState, event});
            return currentState;
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Failed to process appeal workflow event: " + e.getMessage(), e);
            return currentState;
        }
    }

    private <S, E> StateMachineContext<S, E> buildContext(S state) {
        return new DefaultStateMachineContext<>(state, null, null, null);
    }
}
