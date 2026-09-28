package com.tutict.finalassignmentbackend.reliability;

import com.tutict.finalassignmentbackend.service.auth.TokenBlacklistService;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.HikariPoolMXBean;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.concurrent.atomic.AtomicInteger;
import javax.sql.DataSource;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
// After Spring Security (-100), so a revoked token is 401 before a missing ledger key is 400.
@Order(-90)
public class ReliabilityGuardFilter extends OncePerRequestFilter {

    private final boolean loadShedEnabled;
    private final ObjectProvider<DataSource> dataSource;
    private final ReliabilityMetrics metrics;
    private final ObjectProvider<TokenBlacklistService> tokenBlacklistService;
    private final AtomicInteger inFlight = new AtomicInteger();

    public ReliabilityGuardFilter(
            @Value("${app.reliability.load-shed:true}") boolean loadShedEnabled,
            ObjectProvider<DataSource> dataSource,
            ReliabilityMetrics metrics,
            ObjectProvider<TokenBlacklistService> tokenBlacklistService) {
        this.loadShedEnabled = loadShedEnabled;
        this.dataSource = dataSource;
        this.metrics = metrics;
        this.tokenBlacklistService = tokenBlacklistService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String path = request.getRequestURI();
        String method = request.getMethod();
        if (isLoginOrRefresh(path) && !redisReachable()) {
            metrics.dependencyTimeout();
            response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            response.setHeader(HttpHeaders.RETRY_AFTER, "1");
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write("{\"success\":false,\"errorCode\":\"DEPENDENCY_TIMEOUT\",\"message\":\"Redis is unavailable\"}");
            metrics.noteStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            return;
        }
        if (requiresLedgerKey(method, path) && !hasIdempotencyKey(request)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write("{\"success\":false,\"errorCode\":\"MISSING_HEADER\",\"message\":\"Missing required header: Idempotency-Key\"}");
            metrics.noteStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        int admitted = inFlight.incrementAndGet();
        try {
            if (loadShedEnabled && shouldShed(method, path, admitted)) {
                metrics.loadShed();
                response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
                response.setHeader(HttpHeaders.RETRY_AFTER, "1");
                response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                response.getWriter().write("{\"success\":false,\"errorCode\":\"LOAD_SHED\",\"message\":\"Overloaded\"}");
                metrics.noteStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
                return;
            }
            chain.doFilter(request, response);
            metrics.noteStatus(response.getStatus());
        } finally {
            inFlight.decrementAndGet();
        }
    }

    private boolean shouldShed(String method, String path, int admitted) {
        DataSource source = dataSource.getIfAvailable();
        if (!(source instanceof HikariDataSource hikari)) {
            return false;
        }
        int maxPool = hikari.getMaximumPoolSize();
        if (LoadShedPolicy.shedWhenBusy(method, path, admitted, maxPool)) {
            return true;
        }
        HikariPoolMXBean pool = hikari.getHikariPoolMXBean();
        if (pool == null || pool.getTotalConnections() <= 0) {
            return false;
        }
        double utilization = maxPool == 0 ? 0d : (double) pool.getActiveConnections() / maxPool;
        return LoadShedPolicy.shed(method, path, utilization, pool.getThreadsAwaitingConnection(), pool.getIdleConnections());
    }

    private boolean redisReachable() {
        TokenBlacklistService service = tokenBlacklistService.getIfAvailable();
        return service == null || service.redisReachable();
    }

    private static boolean isLoginOrRefresh(String path) {
        return path != null && (path.startsWith("/api/auth/login") || path.startsWith("/api/auth/refresh"));
    }

    private static boolean requiresLedgerKey(String method, String path) {
        if (path == null) {
            return false;
        }
        String verb = method == null ? "" : method.toUpperCase();
        if ("POST".equals(verb)) {
            return path.equals("/api/payments")
                    || path.equals("/api/fines")
                    || path.equals("/api/deductions")
                    || path.equals("/api/appeals")
                    || path.matches("/api/appeals/\\d+/reviews");
        }
        return "PUT".equals(verb) && (path.matches("/api/appeals/\\d+") || path.matches("/api/appeals/reviews/\\d+"));
    }

    private static boolean hasIdempotencyKey(HttpServletRequest request) {
        String header = request.getHeader("Idempotency-Key");
        return header != null && !header.isBlank();
    }
}
