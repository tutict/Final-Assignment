package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class LoadShedPolicyTest {

    @Test
    void matchesLedgerPolicy() {
        assertTrue(LoadShedPolicy.shed("GET", "/api/auth/me", 0.8, 0, 1));
        assertFalse(LoadShedPolicy.shed("GET", "/api/payments/1", 0.9, 0, 0));
        assertTrue(LoadShedPolicy.shed("POST", "/api/payments", 0.9, 0, 0));
        assertTrue(LoadShedPolicy.shed("POST", "api/payments", 0.1, 1, 0));
        assertFalse(LoadShedPolicy.shed("GET", "actuator/health", 1.0, 4, 0));
        assertTrue(LoadShedPolicy.shedWhenBusy("POST", "/api/payments", 21, 20));
        assertTrue(LoadShedPolicy.shedWhenBusy("GET", "/api/auth/me", 21, 20));
        assertFalse(LoadShedPolicy.shedWhenBusy("POST", "/api/payments", 20, 20));
        assertFalse(LoadShedPolicy.shedWhenBusy("GET", "/api/payments/1", 40, 20));
        assertFalse(LoadShedPolicy.shedWhenBusy("GET", "/q/health", 40, 20));
    }
}
