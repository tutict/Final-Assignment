package com.tutict.finalassignmentbackend.governance.core;

@FunctionalInterface
public interface EventIntentClassifier<E, S> {

    MutationSideEffectPolicy classify(E event, S currentState);
}
