package com.tutict.finalassignmentcloud.observability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.tutict.finalassignmentcloud.exception.DependencyUnavailableException;
import com.tutict.finalassignmentcloud.exception.global.GlobalExceptionHandler;
import java.sql.SQLException;
import java.sql.SQLTransientConnectionException;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.transaction.CannotCreateTransactionException;

class LedgerConnectionSignalsTest {

    @Test
    void genericHandlerShedsAWrappedLedgerPoolWait() {
        SQLTransientConnectionException timeout = new SQLTransientConnectionException(
                "Connection is not available, request timed out after 250ms.");
        CannotCreateTransactionException wrapped = new CannotCreateTransactionException(
                "Could not open JDBC Connection for transaction", timeout);
        assertTrue(LedgerConnectionSignals.connectionWait(wrapped));
        assertFalse(LedgerConnectionSignals.connectionWait(new CannotCreateTransactionException(
                "Could not open JDBC Connection for transaction", new SQLException("Access denied"))));

        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/payments");
        request.setRequestURI("/api/payments");
        ResponseEntity<?> response = new GlobalExceptionHandler().handleGenericException(wrapped, request);
        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, response.getStatusCode());
        assertEquals("1", response.getHeaders().getFirst("Retry-After"));
        assertEquals("DEPENDENCY_TIMEOUT", ((java.util.Map<?, ?>) response.getBody()).get("errorCode"));
    }


    @Test
    void dependencyShedCarriesRetryAfter() {
        assertTrue(DependencyUnavailableException.unavailable(503));
        assertTrue(DependencyUnavailableException.unavailable(-1));
        assertFalse(DependencyUnavailableException.unavailable(404));
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/auth/me");
        request.setRequestURI("/api/auth/me");
        ResponseEntity<?> response = new GlobalExceptionHandler().handleDependencyUnavailable(
                new DependencyUnavailableException("user service shed", new IllegalStateException("503")),
                request);
        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, response.getStatusCode());
        assertEquals("1", response.getHeaders().getFirst("Retry-After"));
        assertEquals("DEPENDENCY_TIMEOUT", ((java.util.Map<?, ?>) response.getBody()).get("errorCode"));
    }
    @Test
    void ordinaryFailureStays500() {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/payments");
        request.setRequestURI("/api/payments");
        ResponseEntity<?> response = new GlobalExceptionHandler()
                .handleGenericException(new IllegalStateException("validation"), request);
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertFalse(response.getHeaders().containsHeader("Retry-After"));
    }
}
