package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.SQLTransientConnectionException;
import org.junit.jupiter.api.Test;

class LedgerConnectionPolicyTest {

    @Test
    void ledgerWritesRecognizeAWrappedConnectionWait() {
        assertTrue(LedgerConnectionPolicy.connectionWaitOnLedgerWrite("POST", "/api/payments"));
        assertTrue(LedgerConnectionPolicy.connectionWaitOnLedgerWrite("POST", "api/workflow/appeals/3/events/APPROVE"));
        assertFalse(LedgerConnectionPolicy.connectionWaitOnLedgerWrite("GET", "/api/payments"));
        assertFalse(LedgerConnectionPolicy.connectionWaitOnLedgerWrite("POST", "/api/users"));
        SQLTransientConnectionException timeout = new SQLTransientConnectionException("Acquisition timeout");
        assertTrue(LedgerConnectionPolicy.connectionWait(new IllegalStateException("wrapped", timeout)));
        assertFalse(LedgerConnectionPolicy.connectionWait(new IllegalStateException("validation")));
        assertTrue(LedgerConnectionPolicy.connectionWait(new IllegalStateException(
                "Error 1213 (40001): Deadlock found when trying to get lock")));
        assertTrue(LedgerConnectionPolicy.connectionWait(new java.sql.SQLException(
                "Lock wait timeout exceeded; try restarting transaction", "HY000", 1205)));
        assertTrue(LedgerConnectionPolicy.connectionWait(new IllegalStateException("Connection pool reached max wait queue size of 24")));
    }
}
