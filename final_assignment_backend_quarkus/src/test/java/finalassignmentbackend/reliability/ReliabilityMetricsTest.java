package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class ReliabilityMetricsTest {

    @Test
    void prometheusShowsIncrementedCounters() {
        ReliabilityMetrics metrics = new ReliabilityMetrics();
        metrics.loadShed();
        metrics.idempotencyConflict();
        metrics.dependencyTimeout();
        metrics.kafkaPublishFailed();
        metrics.aiFallback();
        metrics.noteStatus(201);
        metrics.noteStatus(409);
        metrics.noteStatus(503);

        String body = metrics.prometheus(1790437499L, 2L, 15L);
        assertTrue(body.contains("load_shed_total 1\n"));
        assertTrue(body.contains("idempotency_conflict_total 1\n"));
        assertTrue(body.contains("dependency_timeout_total 1\n"));
        assertTrue(body.contains("kafka_publish_failed_total 1\n"));
        assertTrue(body.contains("ai_fallback_total 1\n"));
        assertTrue(body.contains("backup_last_success_timestamp 1790437499\n"));
        assertTrue(body.contains("db_pool_awaiting 2\n"));
        assertTrue(body.contains("db_pool_blocking_ms 15\n"));
        assertTrue(body.contains("http_responses_2xx_total 1\n"));
        assertTrue(body.contains("http_responses_4xx_total 1\n"));
        assertTrue(body.contains("http_responses_5xx_total 1\n"));
    }
}
