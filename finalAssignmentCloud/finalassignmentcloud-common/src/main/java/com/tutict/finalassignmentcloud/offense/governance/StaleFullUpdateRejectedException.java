package com.tutict.finalassignmentcloud.offense.governance;

public final class StaleFullUpdateRejectedException extends RuntimeException {

    private final OffenseGovernanceDecision decision;

    public StaleFullUpdateRejectedException(Long offenseId) {
        super("Stale Offense FULL_UPDATE rejected for id=" + offenseId);
        this.decision = OffenseGovernanceLogFactory.staleKafkaRejected(offenseId, null, null);
    }

    public StaleFullUpdateRejectedException(OffenseGovernanceDecision decision) {
        super("Stale Offense " + decision.semanticEventType() + " rejected for id=" + decision.offenseId());
        this.decision = decision;
    }

    public OffenseGovernanceDecision decision() {
        return decision;
    }
}
