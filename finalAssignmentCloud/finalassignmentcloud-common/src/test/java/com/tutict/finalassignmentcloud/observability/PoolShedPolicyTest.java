package com.tutict.finalassignmentcloud.observability;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class PoolShedPolicyTest {

    @Test
    void nonLedgerGetsShedAtEightyPercentAndLedgerWritesWaitForThePool() {
        assertTrue(PoolShedPolicy.shed("GET", "/api/users", 0.8, 0, 1));
        assertFalse(PoolShedPolicy.shed("GET", "/api/payments/1", 0.9, 0, 0));
        assertTrue(PoolShedPolicy.shed("POST", "/api/payments", 0.9, 0, 0));
        assertTrue(PoolShedPolicy.shed("POST", "/api/payments", 0.1, 1, 0));
        assertFalse(PoolShedPolicy.shed("GET", "/actuator/health", 1.0, 4, 0));
        assertTrue(PoolShedPolicy.shedWhenBusy("GET", "/api/auth/me", 33, 32));
        assertFalse(PoolShedPolicy.shedWhenBusy("GET", "/api/auth/me", 32, 32));
        assertFalse(PoolShedPolicy.shedWhenBusy("GET", "/api/payments", 40, 32));
        assertTrue(PoolShedPolicy.shedWhenBusy("POST", "/api/payments", 33, 32));
        assertFalse(PoolShedPolicy.shedWhenBusy("GET", "/actuator/health", 100, 32));
        assertFalse(PoolShedPolicy.shed("POST", "/api/users", 0.95, 0, 0));
    }
}
