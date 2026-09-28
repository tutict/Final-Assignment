package com.tutict.finalassignmentcloud.gateway;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.mock.http.server.reactive.MockServerHttpRequest;
import org.springframework.mock.web.server.MockServerWebExchange;
import reactor.core.publisher.Mono;

class TraceIdGlobalFilterTest {

    @Test
    void responseHeaderIsReplacedWithTheSinglePropagatedId() {
        MockServerWebExchange exchange = MockServerWebExchange.from(
                MockServerHttpRequest.get("/api/payments").header("X-Trace-Id", "probe-trace").build());
        new TraceIdGlobalFilter().filter(exchange, ex -> Mono.empty()).block();

        HttpHeaders upstream = new HttpHeaders();
        upstream.add("X-Trace-Id", "probe-trace");
        upstream.add("X-Trace-Id", "probe-trace");
        HttpHeaders filtered = new TraceIdResponseHeadersFilter().filter(upstream, exchange);

        assertEquals(List.of("probe-trace"), filtered.get("X-Trace-Id"));
        assertEquals("probe-trace", exchange.getRequest().getHeaders().getFirst("X-Trace-Id"));
    }
}
