package com.tutict.finalassignmentcloud.offense.governance;

public enum FullUpdateCompatibilityMode {
    LEGACY_SHADOW(false),
    GUARDED_COMPATIBILITY(true);

    private final boolean enforceGuardedMerge;

    FullUpdateCompatibilityMode(boolean enforceGuardedMerge) {
        this.enforceGuardedMerge = enforceGuardedMerge;
    }

    public boolean enforceGuardedMerge() {
        return enforceGuardedMerge;
    }
}
