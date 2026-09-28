package com.tutict.finalassignmentcloud.traffic.reliability;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.SQLException;
import java.sql.SQLTransientConnectionException;
import org.junit.jupiter.api.Test;
import org.springframework.transaction.CannotCreateTransactionException;

class LedgerConnectionPolicyTest {

    @Test
    void ledgerWritesAreConnectionWaitFailures() {
        assertTrue(LedgerConnectionPolicy.connectionWaitOnLedgerWrite("POST", "/api/payments"));
        assertTrue(LedgerConnectionPolicy.connectionWaitOnLedgerWrite("put", "api/fines/1"));
        assertFalse(LedgerConnectionPolicy.connectionWaitOnLedgerWrite("GET", "/api/payments"));
        assertFalse(LedgerConnectionPolicy.connectionWaitOnLedgerWrite("POST", "/api/auth/login"));
    }

    @Test
    void wrappedPoolTimeoutIsAConnectionWait() {
        SQLTransientConnectionException timeout = new SQLTransientConnectionException(
                "Connection is not available, request timed out after 250ms.");
        assertTrue(LedgerConnectionPolicy.connectionWait(new CannotCreateTransactionException(
                "Could not open JDBC Connection for transaction", timeout)));
        assertFalse(LedgerConnectionPolicy.connectionWait(new CannotCreateTransactionException(
                "Could not open JDBC Connection for transaction", new SQLException("Access denied"))));
    }
}
