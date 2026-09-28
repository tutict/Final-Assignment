package com.tutict.finalassignmentcloud.gateway;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.mock.http.server.reactive.MockServerHttpRequest;
import org.springframework.mock.web.server.MockServerWebExchange;
import reactor.core.publisher.Mono;

class GatewayResponseMetricsTest {

    @Test
    void countsSuccessRejectionAndFailure() {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        GatewayResponseMetrics filter = new GatewayResponseMetrics(registry);

        filter.filter(exchange(), ex -> {
            ex.getResponse().setStatusCode(HttpStatus.OK);
            return Mono.empty();
        }).block();
        filter.filter(exchange(), ex -> {
            ex.getResponse().setStatusCode(HttpStatus.TOO_MANY_REQUESTS);
            return Mono.empty();
        }).block();
        filter.filter(exchange(), ex -> Mono.error(new IllegalStateException("down"))).onErrorComplete().block();

        assertEquals(1d, registry.get("http_responses_2xx_total").counter().count());
        assertEquals(1d, registry.get("http_responses_4xx_total").counter().count());
        assertEquals(1d, registry.get("http_responses_5xx_total").counter().count());
        assertTrue(filter.getOrder() < new LoginRateLimitGlobalFilter().getOrder());
    }

    private static MockServerWebExchange exchange() {
        return MockServerWebExchange.from(MockServerHttpRequest.get("/api/payments").build());
    }
}