package com.tutict.finalassignmentbackend.offense.governance;

import java.util.Arrays;
import java.util.EnumSet;
import java.util.Set;

public record MutationSideEffectPolicy(
        SemanticEventType semanticEventType,
        Set<MutationSideEffect> sideEffects
) {
    public MutationSideEffectPolicy {
        semanticEventType = semanticEventType == null ? SemanticEventType.UNKNOWN : semanticEventType;
        sideEffects = normalize(sideEffects);
    }

    public static MutationSideEffectPolicy of(SemanticEventType type, MutationSideEffect... sideEffects) {
        return new MutationSideEffectPolicy(type, fromArray(sideEffects));
    }

    public boolean has(MutationSideEffect sideEffect) {
        return sideEffects.contains(sideEffect);
    }

    private static Set<MutationSideEffect> normalize(Set<MutationSideEffect> sideEffects) {
        if (sideEffects == null || sideEffects.isEmpty()) {
            return Set.of(MutationSideEffect.NONE);
        }
        EnumSet<MutationSideEffect> normalized = EnumSet.copyOf(sideEffects);
        if (normalized.size() > 1) {
            normalized.remove(MutationSideEffect.NONE);
        }
        return Set.copyOf(normalized);
    }

    private static Set<MutationSideEffect> fromArray(MutationSideEffect[] sideEffects) {
        if (sideEffects == null || sideEffects.length == 0) {
            return Set.of(MutationSideEffect.NONE);
        }
        EnumSet<MutationSideEffect> set = EnumSet.noneOf(MutationSideEffect.class);
        Arrays.stream(sideEffects)
                .filter(effect -> effect != null)
                .forEach(set::add);
        if (set.isEmpty()) {
            set.add(MutationSideEffect.NONE);
        }
        return set;
    }
}
