package com.tutict.finalassignmentbackend.reliability;

import static org.assertj.core.api.Assertions.assertThat;
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
        ReliabilityMetrics metrics = new ReliabilityMetrics(registry);
        metrics.backupSucceededAtEpochSeconds(10L);
        AtomicLong source = new AtomicLong(10L);
        metrics.useBackupReader(source::get);
        source.set(20L);

        assertThat(registry.get("backup_last_success_timestamp").gauge().value()).isEqualTo(20d);
    }

    @Test
    void failedReadKeepsThePreviousTimestamp() {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        ReliabilityMetrics metrics = new ReliabilityMetrics(registry);
        metrics.backupSucceededAtEpochSeconds(10L);
        metrics.useBackupReader(() -> {
            throw new IllegalStateException("backup table unavailable");
        });

        assertThat(registry.get("backup_last_success_timestamp").gauge().value()).isEqualTo(10d);
    }

    @Test
    void unsignedTimestampIsReadAsLong() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        when(jdbcTemplate.queryForObject(anyString(), eq(Number.class))).thenReturn(new BigInteger("1790576821"));

        assertThat(BackupSuccessGauge.readEpoch(jdbcTemplate)).isEqualTo(1790576821L);
    }
}
