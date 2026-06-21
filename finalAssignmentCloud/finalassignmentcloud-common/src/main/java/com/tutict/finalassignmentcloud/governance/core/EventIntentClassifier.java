package com.tutict.finalassignmentcloud.governance.core;

@FunctionalInterface
public interface EventIntentClassifier<E, S> {

    MutationSideEffectPolicy classify(E event, S currentState);
}
