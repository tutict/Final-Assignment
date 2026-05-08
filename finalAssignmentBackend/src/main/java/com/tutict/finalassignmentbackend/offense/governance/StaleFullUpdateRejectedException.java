package com.tutict.finalassignmentbackend.offense.governance;

public final class StaleFullUpdateRejectedException extends RuntimeException {

    public StaleFullUpdateRejectedException(Long offenseId) {
        super("Stale Offense FULL_UPDATE rejected for id=" + offenseId);
    }
}
