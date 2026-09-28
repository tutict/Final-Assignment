package com.tutict.finalassignmentcloud.traffic.reliability;

import com.tutict.finalassignmentcloud.observability.PoolLoadShedFilter;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariPoolMXBean;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import javax.sql.DataSource;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.annotation.Order;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
// After Spring Security (-100), so a revoked token is 401 before a missing ledger key is 400.
@Order(-90)
public class TrafficReliabilityFilter extends OncePerRequestFilter {

    private final boolean loadShedEnabled;
    private final ObjectProvider<DataSource> dataSource;
    private final TrafficReliabilityMetrics metrics;

    public TrafficReliabilityFilter(
            @Value("${app.reliability.load-shed:true}") boolean loadShedEnabled,
            ObjectProvider<DataSource> dataSource,
            TrafficReliabilityMetrics metrics) {
        this.loadShedEnabled = loadShedEnabled;
        this.dataSource = dataSource;
        this.metrics = metrics;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        request.setAttribute(PoolLoadShedFilter.HANDLED, Boolean.TRUE);
        if (LedgerKeyPolicy.requiresKey(request.getMethod(), request.getRequestURI()) && !hasIdempotencyKey(request)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write("{\"errorCode\":\"MISSING_HEADER\",\"message\":\"Missing required header: Idempotency-Key\"}");
            metrics.noteStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        if (loadShedEnabled && shouldShed(request.getMethod(), request.getRequestURI())) {
            metrics.loadShed();
            response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            response.setHeader("Retry-After", "1");
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write("{\"errorCode\":\"LOAD_SHED\",\"message\":\"Overloaded\"}");
            metrics.noteStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            return;
        }
        chain.doFilter(request, response);
        metrics.noteStatus(response.getStatus());
    }

    private static boolean hasIdempotencyKey(HttpServletRequest request) {
        String header = request.getHeader("Idempotency-Key");
        return header != null && !header.isBlank();
    }

    private boolean shouldShed(String method, String path) {
        DataSource source = dataSource.getIfAvailable();
        if (!(source instanceof HikariDataSource hikari)) {
            return false;
        }
        HikariPoolMXBean pool = hikari.getHikariPoolMXBean();
        if (pool == null || pool.getTotalConnections() <= 0) {
            return false;
        }
        double utilization = hikari.getMaximumPoolSize() == 0
                ? 0d
                : (double) pool.getActiveConnections() / hikari.getMaximumPoolSize();
        return LoadShedPolicy.shed(method, path, utilization, pool.getThreadsAwaitingConnection(), pool.getIdleConnections());
    }
}
