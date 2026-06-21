package com.tutict.finalassignmentcloud.system.appeal.domain.policy;

import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;

import java.util.EnumMap;
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;

public class AppealTransitionPolicy {

    public enum TransitionDecision {
        APPLY,
        NO_OP,
        INVALID
    }

    private static final Set<AppealProcessState> TERMINAL_STATES = EnumSet.of(
            AppealProcessState.APPROVED,
            AppealProcessState.REJECTED,
            AppealProcessState.WITHDRAWN
    );

    private static final Map<AppealProcessState, Set<AppealProcessState>> ALLOWED_TRANSITIONS = allowedTransitions();

    public TransitionDecision decide(String currentStatus, AppealProcessState requestedState) {
        if (requestedState == null) {
            return TransitionDecision.NO_OP;
        }
        AppealProcessState currentState = AppealProcessState.fromCode(currentStatus);
        if (currentState == null) {
            return TransitionDecision.APPLY;
        }
        if (currentState == requestedState) {
            return TransitionDecision.NO_OP;
        }
        if (isTerminal(currentState)) {
            return TransitionDecision.INVALID;
        }
        return ALLOWED_TRANSITIONS.getOrDefault(currentState, Set.of()).contains(requestedState)
                ? TransitionDecision.APPLY
                : TransitionDecision.INVALID;
    }

    public boolean isTerminal(String status) {
        AppealProcessState state = AppealProcessState.fromCode(status);
        return state != null && isTerminal(state);
    }

    public Set<AppealProcessState> terminalStates() {
        return Set.copyOf(TERMINAL_STATES);
    }

    public Set<AppealProcessState> allowedTargets(String currentStatus) {
        AppealProcessState currentState = AppealProcessState.fromCode(currentStatus);
        if (currentState == null) {
            return EnumSet.allOf(AppealProcessState.class);
        }
        if (isTerminal(currentState)) {
            return EnumSet.of(currentState);
        }
        return Set.copyOf(ALLOWED_TRANSITIONS.getOrDefault(currentState, Set.of()));
    }

    private static boolean isTerminal(AppealProcessState state) {
        return TERMINAL_STATES.contains(state);
    }

    private static Map<AppealProcessState, Set<AppealProcessState>> allowedTransitions() {
        Map<AppealProcessState, Set<AppealProcessState>> transitions = new EnumMap<>(AppealProcessState.class);
        transitions.put(AppealProcessState.UNPROCESSED, EnumSet.of(
                AppealProcessState.UNDER_REVIEW,
                AppealProcessState.APPROVED,
                AppealProcessState.REJECTED,
                AppealProcessState.WITHDRAWN
        ));
        transitions.put(AppealProcessState.UNDER_REVIEW, EnumSet.of(
                AppealProcessState.UNPROCESSED,
                AppealProcessState.APPROVED,
                AppealProcessState.REJECTED,
                AppealProcessState.WITHDRAWN
        ));
        transitions.put(AppealProcessState.APPROVED, EnumSet.of(AppealProcessState.APPROVED));
        transitions.put(AppealProcessState.REJECTED, EnumSet.of(AppealProcessState.REJECTED));
        transitions.put(AppealProcessState.WITHDRAWN, EnumSet.of(AppealProcessState.WITHDRAWN));
        return transitions;
    }
}
