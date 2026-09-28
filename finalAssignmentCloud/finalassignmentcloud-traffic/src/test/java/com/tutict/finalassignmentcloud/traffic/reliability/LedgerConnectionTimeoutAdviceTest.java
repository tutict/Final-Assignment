package com.tutict.finalassignmentcloud.traffic.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.lang.reflect.Method;
import java.sql.SQLTransientConnectionException;
import org.junit.jupiter.api.Test;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.transaction.CannotCreateTransactionException;
import org.springframework.web.method.annotation.ExceptionHandlerMethodResolver;

class LedgerConnectionTimeoutAdviceTest {

    @Test
    void adviceRunsBeforeTheGenericHandler() {
        Order order = LedgerConnectionTimeoutAdvice.class.getAnnotation(Order.class);
        assertEquals(Ordered.HIGHEST_PRECEDENCE, order.value());
    }

    @Test
    void transactionWrapperOnALedgerPostIs503() throws Exception {
        CannotCreateTransactionException wrapped = wrappedTimeout();
        Method method = new ExceptionHandlerMethodResolver(LedgerConnectionTimeoutAdvice.class).resolveMethod(wrapped);
        assertEquals("connectionWait", method.getName());
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        LedgerConnectionTimeoutAdvice advice = new LedgerConnectionTimeoutAdvice(new TrafficReliabilityMetrics(registry));
        ResponseEntity<?> response = advice.connectionWait(request("POST", "/api/payments"), wrapped);
        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, response.getStatusCode());
        assertEquals("1", response.getHeaders().getFirst("Retry-After"));
        assertEquals("DEPENDENCY_TIMEOUT", ((java.util.Map<?, ?>) response.getBody()).get("errorCode"));
        assertEquals(1d, registry.get("dependency_timeout_total").counter().count());
    }

    @Test
    void nonLedgerPoolWaitStays500() {
        LedgerConnectionTimeoutAdvice advice = new LedgerConnectionTimeoutAdvice(new TrafficReliabilityMetrics(new SimpleMeterRegistry()));
        ResponseEntity<?> response = advice.connectionWait(request("GET", "/api/payments"), wrappedTimeout());
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertFalse(response.getHeaders().containsHeader("Retry-After"));
        assertEquals("DATA_ACCESS", ((java.util.Map<?, ?>) response.getBody()).get("errorCode"));
    }

    private static CannotCreateTransactionException wrappedTimeout() {
        return new CannotCreateTransactionException(
                "Could not open JDBC Connection for transaction",
                new SQLTransientConnectionException("Connection is not available, request timed out after 250ms."));
    }

    private static MockHttpServletRequest request(String method, String path) {
        MockHttpServletRequest request = new MockHttpServletRequest(method, path);
        request.setRequestURI(path);
        return request;
    }
}
