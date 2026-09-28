package com.tutict.finalassignmentcloud.traffic.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.math.BigInteger;
import java.util.concurrent.atomic.AtomicLong;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class BackupTimestampGaugeTest {

    @Test
    void scrapeReadsTheCurrentBackupTimestamp() {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        TrafficReliabilityMetrics metrics = new TrafficReliabilityMetrics(registry);
        metrics.backupSucceededAtEpochSeconds(10L);
        AtomicLong source = new AtomicLong(10L);
        metrics.useBackupReader(source::get);
        source.set(20L);

        assertEquals(20d, registry.get("backup_last_success_timestamp").gauge().value());
    }

    @Test
    void failedReadKeepsThePreviousTimestamp() {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        TrafficReliabilityMetrics metrics = new TrafficReliabilityMetrics(registry);
        metrics.backupSucceededAtEpochSeconds(10L);
        metrics.useBackupReader(() -> {
            throw new IllegalStateException("backup table unavailable");
        });

        assertEquals(10d, registry.get("backup_last_success_timestamp").gauge().value());
    }

    @Test
    void unsignedTimestampIsReadAsLong() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        when(jdbcTemplate.queryForObject(anyString(), eq(Number.class))).thenReturn(new BigInteger("1790576821"));

        assertEquals(1790576821L, BackupSuccessGauge.readEpoch(jdbcTemplate));
    }
}
