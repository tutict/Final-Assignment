package com.tutict.finalassignmentcloud.traffic.reliability;

import jakarta.servlet.http.HttpServletRequest;
import java.sql.SQLTransientConnectionException;
import java.util.Map;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.CannotGetJdbcConnectionException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.CannotCreateTransactionException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class LedgerConnectionTimeoutAdvice {

    private final TrafficReliabilityMetrics metrics;

    public LedgerConnectionTimeoutAdvice(TrafficReliabilityMetrics metrics) {
        this.metrics = metrics;
    }

    @ExceptionHandler({
            CannotGetJdbcConnectionException.class,
            SQLTransientConnectionException.class,
            CannotCreateTransactionException.class
    })
    public ResponseEntity<Map<String, String>> connectionWait(HttpServletRequest request, Exception ex) {
        boolean wait = LedgerConnectionPolicy.connectionWait(ex);
        boolean ledger = LedgerConnectionPolicy.connectionWaitOnLedgerWrite(request.getMethod(), request.getRequestURI());
        if (!wait) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("errorCode", "DATA_ACCESS"));
        }
        if (!ledger) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("errorCode", "DATA_ACCESS", "message", "Database connection failed"));
        }
        metrics.dependencyTimeout();
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .header("Retry-After", "1")
                .body(Map.of("errorCode", "DEPENDENCY_TIMEOUT", "message", "Database connection wait exceeded 200ms"));
    }
}
