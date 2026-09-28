package com.tutict.finalassignmentbackend.reliability;

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
        assertFalse(LedgerConnectionPolicy.connectionWaitOnLedgerWrite("GET", "/api/payments"));
        assertFalse(LedgerConnectionPolicy.connectionWaitOnLedgerWrite("POST", "/api/auth/login"));
    }

    @Test
    void wrappedPoolTimeoutIsAConnectionWait() {
        SQLTransientConnectionException timeout = new SQLTransientConnectionException(
                "HikariPool-1 - Connection is not available, request timed out after 250ms.");
        CannotCreateTransactionException wrapped = new CannotCreateTransactionException(
                "Could not open JDBC Connection for transaction", timeout);
        assertTrue(LedgerConnectionPolicy.connectionWait(new IllegalStateException("outer", wrapped)));
        assertFalse(LedgerConnectionPolicy.connectionWait(
                new CannotCreateTransactionException("Could not open JDBC Connection for transaction",
                        new SQLException("Access denied for user"))));
    }
}
