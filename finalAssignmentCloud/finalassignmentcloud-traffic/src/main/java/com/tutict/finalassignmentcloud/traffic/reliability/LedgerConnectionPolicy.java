package com.tutict.finalassignmentcloud.traffic.reliability;

import com.tutict.finalassignmentcloud.observability.LedgerConnectionSignals;

public final class LedgerConnectionPolicy {

    private LedgerConnectionPolicy() {
    }

    public static boolean connectionWaitOnLedgerWrite(String method, String path) {
        return LedgerConnectionSignals.ledgerWrite(method, path);
    }

    public static boolean connectionWait(Throwable failure) {
        return LedgerConnectionSignals.connectionWait(failure);
    }
}
