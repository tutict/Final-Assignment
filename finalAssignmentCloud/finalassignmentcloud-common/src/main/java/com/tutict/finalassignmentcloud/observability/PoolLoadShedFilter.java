package com.tutict.finalassignmentcloud.observability;

import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariPoolMXBean;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.concurrent.atomic.AtomicInteger;
import javax.sql.DataSource;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 30)
public class PoolLoadShedFilter extends OncePerRequestFilter {

    public static final String HANDLED = "com.tutict.finalassignmentcloud.pool-shed";

    private final boolean enabled;
    private final ObjectProvider<DataSource> dataSource;
    private final Counter loadShed;
    private final AtomicInteger inFlight = new AtomicInteger();

    public PoolLoadShedFilter(
            @Value("${app.reliability.load-shed:${RELIABILITY_LOAD_SHED:true}}") boolean enabled,
            ObjectProvider<DataSource> dataSource,
            ObjectProvider<MeterRegistry> meters) {
        this.enabled = enabled;
        this.dataSource = dataSource;
        MeterRegistry registry = meters.getIfAvailable();
        this.loadShed = registry == null ? null : Counter.builder("load_shed_total").register(registry);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        if (Boolean.TRUE.equals(request.getAttribute(HANDLED))) {
            chain.doFilter(request, response);
            return;
        }
        int admitted = inFlight.incrementAndGet();
        request.setAttribute(HANDLED, Boolean.TRUE);
        try {
            if (!enabled || !shouldShed(request, admitted)) {
                chain.doFilter(request, response);
                return;
            }
            if (loadShed != null) {
                loadShed.increment();
            }
            response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            response.setHeader("Retry-After", "1");
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write("{\"errorCode\":\"LOAD_SHED\",\"message\":\"Overloaded\"}");
        } finally {
            inFlight.decrementAndGet();
        }
    }

    private boolean shouldShed(HttpServletRequest request, int admitted) {
        DataSource source = dataSource.getIfAvailable();
        if (!(source instanceof HikariDataSource hikari)) {
            return false;
        }
        int maxPool = hikari.getMaximumPoolSize();
        if (PoolShedPolicy.shedWhenBusy(request.getMethod(), request.getRequestURI(), admitted, maxPool)) {
            return true;
        }
        HikariPoolMXBean pool = hikari.getHikariPoolMXBean();
        if (pool == null || maxPool <= 0) {
            return false;
        }
        double utilization = (double) pool.getActiveConnections() / maxPool;
        return PoolShedPolicy.shed(
                request.getMethod(),
                request.getRequestURI(),
                utilization,
                pool.getThreadsAwaitingConnection(),
                pool.getIdleConnections());
    }
}
