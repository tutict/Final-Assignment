package com.tutict.finalassignmentbackend.reliability;

import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariPoolMXBean;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import javax.sql.DataSource;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;

@Component
public class PoolWaitGauge {

    private final ObjectProvider<DataSource> dataSource;

    public PoolWaitGauge(MeterRegistry registry, ObjectProvider<DataSource> dataSource) {
        this.dataSource = dataSource;
        Gauge.builder("db_pool_wait_count", this, PoolWaitGauge::awaiting)
                .strongReference(true)
                .register(registry);
    }

    private static double awaiting(PoolWaitGauge gauge) {
        DataSource source = gauge.dataSource.getIfAvailable();
        if (!(source instanceof HikariDataSource hikari)) {
            return 0d;
        }
        HikariPoolMXBean pool = hikari.getHikariPoolMXBean();
        return pool == null ? 0d : pool.getThreadsAwaitingConnection();
    }
}