package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class LedgerKeyPolicyTest {

    @Test
    void ledgerPostsRequireTheHeader() {
        assertTrue(LedgerKeyPolicy.requiresKey("POST", "api/appeals/4/reviews"));
        assertTrue(LedgerKeyPolicy.requiresKey("POST", "/api/appeals"));
        assertTrue(LedgerKeyPolicy.requiresKey("POST", "/api/fines"));
        assertTrue(LedgerKeyPolicy.requiresKey("POST", "/api/deductions"));
        assertTrue(LedgerKeyPolicy.requiresKey("POST", "/api/payments"));
        assertTrue(LedgerKeyPolicy.requiresKey("POST", "api/workflow/payments/9/events/PAY"));
        assertTrue(LedgerKeyPolicy.requiresKey("POST", "/api/workflow/appeals/3/events/APPROVE"));
        assertFalse(LedgerKeyPolicy.requiresKey("POST", "/api/workflow/offenses/3/events/START"));
        assertFalse(LedgerKeyPolicy.requiresKey("GET", "/api/payments"));
        assertFalse(LedgerKeyPolicy.requiresKey("POST", "/api/offenses"));
        assertTrue(LedgerKeyPolicy.requiresKey("PUT", "/api/appeals/4"));
        assertTrue(LedgerKeyPolicy.requiresKey("PUT", "api/appeals/reviews/9"));
        assertFalse(LedgerKeyPolicy.requiresKey("PUT", "/api/fines/4"));
    }
}
