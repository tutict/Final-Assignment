package com.tutict.finalassignmentcloud.traffic.reliability;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class BackupSuccessGauge {

    static final String LAST_SUCCESS_SQL =
            "SELECT UNIX_TIMESTAMP(MAX(backup_time)) FROM sys_backup_restore WHERE status = 'Success' AND deleted_at IS NULL";

    public BackupSuccessGauge(JdbcTemplate jdbcTemplate, TrafficReliabilityMetrics metrics) {
        metrics.useBackupReader(() -> readEpoch(jdbcTemplate));
    }

    static Long readEpoch(JdbcTemplate jdbcTemplate) {
        Number epoch = jdbcTemplate.queryForObject(LAST_SUCCESS_SQL, Number.class);
        return epoch == null ? null : epoch.longValue();
    }
}
