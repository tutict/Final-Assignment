package com.tutict.finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import com.tutict.finalassignmentbackend.exception.global.GlobalExceptionHandler;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLTransientConnectionException;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.CannotCreateTransactionException;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.method.annotation.ExceptionHandlerMethodResolver;

class LedgerConnectionTimeoutMappingTest {

    @Test
    void transactionWrapperOnALedgerPostIs503() throws Exception {
        CannotCreateTransactionException wrapped = wrappedTimeout();
        Wired wired = wire();
        Method method = new ExceptionHandlerMethodResolver(GlobalExceptionHandler.class).resolveMethod(wrapped);
        assertEquals("handleGenericException", method.getName());

        ResponseEntity<?> response = wired.handler.handleGenericException(ledgerPost(), wrapped);
        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, response.getStatusCode());
        assertEquals("1", response.getHeaders().getFirst(HttpHeaders.RETRY_AFTER));
        assertEquals("DEPENDENCY_TIMEOUT", ((com.tutict.finalassignmentbackend.dto.response.ApiResponse<?>) response.getBody()).getErrorCode());
        assertEquals(1d, wired.registry.get("dependency_timeout_total").counter().count());
    }

    @Test
    void directPoolTimeoutStillUsesTheSpecificHandler() throws Exception {
        SQLTransientConnectionException timeout = new SQLTransientConnectionException("Connection is not available");
        Method method = new ExceptionHandlerMethodResolver(GlobalExceptionHandler.class).resolveMethod(timeout);
        assertEquals("handleConnectionWait", method.getName());
        ResponseEntity<?> response = wire().handler.handleConnectionWait(ledgerPost(), timeout);
        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, response.getStatusCode());
        assertEquals("1", response.getHeaders().getFirst(HttpHeaders.RETRY_AFTER));
    }

    @Test
    void nonLedgerAndOrdinaryFailuresStay500() {
        CannotCreateTransactionException wrapped = wrappedTimeout();
        GlobalExceptionHandler handler = wire().handler;
        ResponseEntity<?> login = handler.handleGenericException(request("POST", "/api/auth/login"), wrapped);
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, login.getStatusCode());
        assertFalse(login.getHeaders().containsHeader(HttpHeaders.RETRY_AFTER));
        ResponseEntity<?> read = handler.handleGenericException(request("GET", "/api/payments"), wrapped);
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, read.getStatusCode());
        ResponseEntity<?> ordinary = handler.handleGenericException(ledgerPost(), new IllegalStateException("validation"));
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, ordinary.getStatusCode());
        assertEquals("INTERNAL_ERROR", ((com.tutict.finalassignmentbackend.dto.response.ApiResponse<?>) ordinary.getBody()).getErrorCode());
    }

    @Test
    void realPoolWaitIsWrappedAndMappedTo503() throws Exception {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:mysql://127.0.0.1:3306/traffic?useSSL=false&allowPublicKeyRetrieval=true&characterEncoding=utf8");
        config.setUsername("root");
        config.setPassword("root");
        config.setMaximumPoolSize(1);
        config.setMinimumIdle(0);
        config.setConnectionTimeout(250);
        config.setInitializationFailTimeout(5000);
        config.setPoolName("ledger-wait-test");
        HikariDataSource dataSource = new HikariDataSource(config);
        Connection held = null;
        try {
            try {
                held = dataSource.getConnection();
            } catch (SQLException ex) {
                assumeTrue(false, ex.toString());
            }
            TransactionTemplate template = new TransactionTemplate(new DataSourceTransactionManager(dataSource));
            long started = System.nanoTime();
            CannotCreateTransactionException wrapped = assertThrows(
                    CannotCreateTransactionException.class,
                    () -> template.execute(status -> null));
            long elapsedMs = (System.nanoTime() - started) / 1_000_000L;
            assertTrue(elapsedMs < 1500, "pool wait took " + elapsedMs + "ms");
            assertTrue(LedgerConnectionPolicy.connectionWait(wrapped), wrapped.toString());
            ResponseEntity<?> response = wire().handler.handleGenericException(ledgerPost(), wrapped);
            assertEquals(HttpStatus.SERVICE_UNAVAILABLE, response.getStatusCode());
            assertEquals("1", response.getHeaders().getFirst(HttpHeaders.RETRY_AFTER));
        } finally {
            if (held != null) {
                held.close();
            }
            dataSource.close();
        }
    }

    private static CannotCreateTransactionException wrappedTimeout() {
        SQLTransientConnectionException timeout = new SQLTransientConnectionException(
                "HikariPool-1 - Connection is not available, request timed out after 250ms.");
        return new CannotCreateTransactionException("Could not open JDBC Connection for transaction", timeout);
    }

    private static Wired wire() {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        GlobalExceptionHandler handler = new GlobalExceptionHandler();
        ReflectionTestUtils.setField(handler, "reliabilityMetrics", new ReliabilityMetrics(registry));
        return new Wired(handler, registry);
    }

    private static MockHttpServletRequest ledgerPost() {
        return request("POST", "/api/payments");
    }

    private static MockHttpServletRequest request(String method, String path) {
        MockHttpServletRequest request = new MockHttpServletRequest(method, path);
        request.setRequestURI(path);
        return request;
    }

    private record Wired(GlobalExceptionHandler handler, SimpleMeterRegistry registry) {
    }
}
