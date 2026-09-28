package com.tutict.finalassignmentcloud.traffic.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.Test;

class TrafficReliabilityMetricsTest {

    @Test
    void countersAndBackupGaugeMove() {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        TrafficReliabilityMetrics metrics = new TrafficReliabilityMetrics(registry);
        metrics.loadShed();
        metrics.idempotencyConflict();
        metrics.dependencyTimeout();
        metrics.noteStatus(201);
        metrics.noteStatus(409);
        metrics.noteStatus(503);
        metrics.backupSucceededAtEpochSeconds(1790437499L);

        assertEquals(1d, registry.get("load_shed_total").counter().count());
        assertEquals(1d, registry.get("idempotency_conflict_total").counter().count());
        assertEquals(1d, registry.get("dependency_timeout_total").counter().count());
        assertEquals(1d, registry.get("http_responses_2xx_total").counter().count());
        assertEquals(1d, registry.get("http_responses_4xx_total").counter().count());
        assertEquals(1d, registry.get("http_responses_5xx_total").counter().count());
        assertEquals(1790437499d, registry.get("backup_last_success_timestamp").gauge().value());
    }

    @Test
    void shedPolicyMatchesLedgerRules() {
        assertTrue(LoadShedPolicy.shed("GET", "/api/auth/me", 0.8, 0, 1));
        assertFalse(LoadShedPolicy.shed("GET", "/api/payments/1", 0.9, 0, 0));
        assertTrue(LoadShedPolicy.shed("POST", "/api/payments", 0.9, 0, 0));
        assertTrue(LoadShedPolicy.shed("POST", "/api/payments", 0.1, 1, 0));
        assertFalse(LoadShedPolicy.shed("GET", "/actuator/health", 1.0, 4, 0));
    }
}
