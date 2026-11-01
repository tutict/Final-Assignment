package com.tutict.finalassignmentcloud.observability;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class PoolShedPolicyTest {

    @Test
    void nonLedgerGetsShedOnlyWhenTheQueueIsDeepEnough() {
        assertFalse(PoolShedPolicy.shed("GET", "/api/users", 1.0, 0, 0, 16));
        assertFalse(PoolShedPolicy.shed("GET", "/api/users", 1.0, 7, 0, 16));
        assertTrue(PoolShedPolicy.shed("GET", "/api/users", 1.0, 8, 0, 16));
        assertTrue(PoolShedPolicy.shed("GET", "/api/users", 0.1, 1, 8, 2));
    }

    @Test
    void ledgerAndHealthKeepTheirExistingRules() {
        assertFalse(PoolShedPolicy.shed("GET", "/api/payments/1", 0.9, 0, 0, 16));
        assertTrue(PoolShedPolicy.shed("POST", "/api/payments", 0.9, 0, 0, 16));
        assertTrue(PoolShedPolicy.shed("POST", "/api/payments", 0.1, 1, 0, 16));
        assertTrue(PoolShedPolicy.shed("GET", "/api/auth/me", 0.1, 1, 8, 2));
        assertFalse(PoolShedPolicy.shed("GET", "/api/auth/me", 0.1, 0, 8, 16));
        assertFalse(PoolShedPolicy.shed("GET", "/actuator/health", 1.0, 8, 0, 16));
        assertFalse(PoolShedPolicy.shed("POST", "/api/users", 0.95, 0, 0, 16));
    }
}
