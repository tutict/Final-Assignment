package com.tutict.finalassignmentcloud.offense.governance;

import com.tutict.finalassignmentcloud.entity.offense.OffenseRecord;

public final class OffenseUpdateFreshnessEvaluator {

    private final OffenseStaleUpdatePolicy policy;

    public OffenseUpdateFreshnessEvaluator() {
        this(new OffenseStaleUpdatePolicy());
    }

    public OffenseUpdateFreshnessEvaluator(OffenseStaleUpdatePolicy policy) {
        this.policy = policy;
    }

    public OffenseStaleUpdatePolicy.Decision evaluate(OffenseRecord current,
                                                      OffenseRecord incoming,
                                                      SemanticEventType semanticEventType) {
        OffenseVersionSnapshot currentSnapshot = OffenseVersionSnapshot.from(current, semanticEventType);
        OffenseVersionSnapshot incomingSnapshot = OffenseVersionSnapshot.from(incoming, semanticEventType);
        return policy.decide(currentSnapshot, incomingSnapshot);
    }
}
