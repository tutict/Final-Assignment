package finalassignmentbackend.service.statemachine;

import finalassignmentbackend.config.statemachine.events.AppealProcessEvent;
import finalassignmentbackend.config.statemachine.events.OffenseProcessEvent;
import finalassignmentbackend.config.statemachine.events.PaymentEvent;
import finalassignmentbackend.config.statemachine.states.AppealProcessState;
import finalassignmentbackend.config.statemachine.states.OffenseProcessState;
import finalassignmentbackend.config.statemachine.states.PaymentState;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.EnumMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class StateMachineService {

    private static final Logger LOG = Logger.getLogger(StateMachineService.class.getName());

    private static final Map<OffenseProcessState, Map<OffenseProcessEvent, OffenseProcessState>> OFFENSE_TRANSITIONS =
            buildOffenseTransitions();
    private static final Map<PaymentState, Map<PaymentEvent, PaymentState>> PAYMENT_TRANSITIONS =
            buildPaymentTransitions();
    private static final Map<AppealProcessState, Map<AppealProcessEvent, AppealProcessState>> APPEAL_TRANSITIONS =
            buildAppealTransitions();

    public OffenseProcessState processOffenseState(Long offenseId,
                                                   OffenseProcessState currentState,
                                                   OffenseProcessEvent event) {
        OffenseProcessState newState = transition(currentState, event, OFFENSE_TRANSITIONS);
        if (newState == currentState) {
            LOG.log(Level.WARNING, "Offense {0} event {1} rejected at state {2}",
                    new Object[]{offenseId, event, currentState});
        } else {
            LOG.log(Level.INFO, "Offense {0} state transition {1} -> {2} via {3}",
                    new Object[]{offenseId, currentState, newState, event});
        }
        return newState;
    }

    public PaymentState processPaymentState(Long paymentId,
                                            PaymentState currentState,
                                            PaymentEvent event) {
        PaymentState newState = transition(currentState, event, PAYMENT_TRANSITIONS);
        if (newState == currentState) {
            LOG.log(Level.WARNING, "Payment {0} event {1} rejected at state {2}",
                    new Object[]{paymentId, event, currentState});
        } else {
            LOG.log(Level.INFO, "Payment {0} state transition {1} -> {2} via {3}",
                    new Object[]{paymentId, currentState, newState, event});
        }
        return newState;
    }

    public AppealProcessState processAppealState(Long appealId,
                                                 AppealProcessState currentState,
                                                 AppealProcessEvent event) {
        AppealProcessState newState = transition(currentState, event, APPEAL_TRANSITIONS);
        if (newState == currentState) {
            LOG.log(Level.WARNING, "Appeal {0} event {1} rejected at state {2}",
                    new Object[]{appealId, event, currentState});
        } else {
            LOG.log(Level.INFO, "Appeal {0} state transition {1} -> {2} via {3}",
                    new Object[]{appealId, currentState, newState, event});
        }
        return newState;
    }

    public boolean canTransitionOffenseState(OffenseProcessState currentState, OffenseProcessEvent event) {
        return canTransition(currentState, event, OFFENSE_TRANSITIONS);
    }

    public boolean canTransitionPaymentState(PaymentState currentState, PaymentEvent event) {
        return canTransition(currentState, event, PAYMENT_TRANSITIONS);
    }

    public boolean canTransitionAppealState(AppealProcessState currentState, AppealProcessEvent event) {
        return canTransition(currentState, event, APPEAL_TRANSITIONS);
    }

    private static <S, E> boolean canTransition(S currentState, E event, Map<S, Map<E, S>> transitions) {
        if (currentState == null || event == null) {
            return false;
        }
        Map<E, S> mapping = transitions.get(currentState);
        return mapping != null && mapping.containsKey(event);
    }

    private static <S, E> S transition(S currentState, E event, Map<S, Map<E, S>> transitions) {
        if (currentState == null || event == null) {
            return currentState;
        }
        Map<E, S> mapping = transitions.get(currentState);
        if (mapping == null) {
            return currentState;
        }
        return mapping.getOrDefault(event, currentState);
    }

    private static Map<OffenseProcessState, Map<OffenseProcessEvent, OffenseProcessState>> buildOffenseTransitions() {
        Map<OffenseProcessState, Map<OffenseProcessEvent, OffenseProcessState>> transitions =
                new EnumMap<>(OffenseProcessState.class);

        transitions.put(OffenseProcessState.UNPROCESSED, new EnumMap<>(OffenseProcessEvent.class));
        transitions.get(OffenseProcessState.UNPROCESSED).put(OffenseProcessEvent.START_PROCESSING, OffenseProcessState.PROCESSING);
        transitions.get(OffenseProcessState.UNPROCESSED).put(OffenseProcessEvent.CANCEL, OffenseProcessState.CANCELLED);

        transitions.put(OffenseProcessState.PROCESSING, new EnumMap<>(OffenseProcessEvent.class));
        transitions.get(OffenseProcessState.PROCESSING).put(OffenseProcessEvent.COMPLETE_PROCESSING, OffenseProcessState.PROCESSED);
        transitions.get(OffenseProcessState.PROCESSING).put(OffenseProcessEvent.CANCEL, OffenseProcessState.CANCELLED);

        transitions.put(OffenseProcessState.PROCESSED, new EnumMap<>(OffenseProcessEvent.class));
        transitions.get(OffenseProcessState.PROCESSED).put(OffenseProcessEvent.SUBMIT_APPEAL, OffenseProcessState.APPEALING);
        transitions.get(OffenseProcessState.PROCESSED).put(OffenseProcessEvent.CANCEL, OffenseProcessState.CANCELLED);

        transitions.put(OffenseProcessState.APPEALING, new EnumMap<>(OffenseProcessEvent.class));
        transitions.get(OffenseProcessState.APPEALING).put(OffenseProcessEvent.APPROVE_APPEAL, OffenseProcessState.APPEAL_APPROVED);
        transitions.get(OffenseProcessState.APPEALING).put(OffenseProcessEvent.REJECT_APPEAL, OffenseProcessState.APPEAL_REJECTED);
        transitions.get(OffenseProcessState.APPEALING).put(OffenseProcessEvent.WITHDRAW_APPEAL, OffenseProcessState.PROCESSED);
        transitions.get(OffenseProcessState.APPEALING).put(OffenseProcessEvent.CANCEL, OffenseProcessState.CANCELLED);

        transitions.put(OffenseProcessState.APPEAL_APPROVED, new EnumMap<>(OffenseProcessEvent.class));
        transitions.get(OffenseProcessState.APPEAL_APPROVED).put(OffenseProcessEvent.CANCEL, OffenseProcessState.CANCELLED);

        transitions.put(OffenseProcessState.APPEAL_REJECTED, new EnumMap<>(OffenseProcessEvent.class));
        transitions.get(OffenseProcessState.APPEAL_REJECTED).put(OffenseProcessEvent.CANCEL, OffenseProcessState.CANCELLED);

        transitions.put(OffenseProcessState.CANCELLED, new EnumMap<>(OffenseProcessEvent.class));
        return transitions;
    }

    private static Map<PaymentState, Map<PaymentEvent, PaymentState>> buildPaymentTransitions() {
        Map<PaymentState, Map<PaymentEvent, PaymentState>> transitions =
                new EnumMap<>(PaymentState.class);

        transitions.put(PaymentState.UNPAID, new EnumMap<>(PaymentEvent.class));
        transitions.get(PaymentState.UNPAID).put(PaymentEvent.PARTIAL_PAY, PaymentState.PARTIAL);
        transitions.get(PaymentState.UNPAID).put(PaymentEvent.COMPLETE_PAYMENT, PaymentState.PAID);
        transitions.get(PaymentState.UNPAID).put(PaymentEvent.MARK_OVERDUE, PaymentState.OVERDUE);
        transitions.get(PaymentState.UNPAID).put(PaymentEvent.WAIVE_FINE, PaymentState.WAIVED);

        transitions.put(PaymentState.PARTIAL, new EnumMap<>(PaymentEvent.class));
        transitions.get(PaymentState.PARTIAL).put(PaymentEvent.CONTINUE_PAYMENT, PaymentState.PAID);
        transitions.get(PaymentState.PARTIAL).put(PaymentEvent.MARK_OVERDUE, PaymentState.OVERDUE);
        transitions.get(PaymentState.PARTIAL).put(PaymentEvent.WAIVE_FINE, PaymentState.WAIVED);

        transitions.put(PaymentState.OVERDUE, new EnumMap<>(PaymentEvent.class));
        transitions.get(PaymentState.OVERDUE).put(PaymentEvent.COMPLETE_PAYMENT, PaymentState.PAID);
        transitions.get(PaymentState.OVERDUE).put(PaymentEvent.WAIVE_FINE, PaymentState.WAIVED);

        transitions.put(PaymentState.PAID, new EnumMap<>(PaymentEvent.class));
        transitions.get(PaymentState.PAID).put(PaymentEvent.WAIVE_FINE, PaymentState.WAIVED);

        transitions.put(PaymentState.WAIVED, new EnumMap<>(PaymentEvent.class));
        return transitions;
    }

    private static Map<AppealProcessState, Map<AppealProcessEvent, AppealProcessState>> buildAppealTransitions() {
        Map<AppealProcessState, Map<AppealProcessEvent, AppealProcessState>> transitions =
                new EnumMap<>(AppealProcessState.class);

        transitions.put(AppealProcessState.UNPROCESSED, new EnumMap<>(AppealProcessEvent.class));
        transitions.get(AppealProcessState.UNPROCESSED).put(AppealProcessEvent.START_REVIEW, AppealProcessState.UNDER_REVIEW);
        transitions.get(AppealProcessState.UNPROCESSED).put(AppealProcessEvent.WITHDRAW, AppealProcessState.WITHDRAWN);

        transitions.put(AppealProcessState.UNDER_REVIEW, new EnumMap<>(AppealProcessEvent.class));
        transitions.get(AppealProcessState.UNDER_REVIEW).put(AppealProcessEvent.APPROVE, AppealProcessState.APPROVED);
        transitions.get(AppealProcessState.UNDER_REVIEW).put(AppealProcessEvent.REJECT, AppealProcessState.REJECTED);
        transitions.get(AppealProcessState.UNDER_REVIEW).put(AppealProcessEvent.WITHDRAW, AppealProcessState.WITHDRAWN);

        transitions.put(AppealProcessState.REJECTED, new EnumMap<>(AppealProcessEvent.class));
        transitions.get(AppealProcessState.REJECTED).put(AppealProcessEvent.REOPEN_REVIEW, AppealProcessState.UNDER_REVIEW);

        transitions.put(AppealProcessState.APPROVED, new EnumMap<>(AppealProcessEvent.class));
        transitions.put(AppealProcessState.WITHDRAWN, new EnumMap<>(AppealProcessEvent.class));
        return transitions;
    }
}
