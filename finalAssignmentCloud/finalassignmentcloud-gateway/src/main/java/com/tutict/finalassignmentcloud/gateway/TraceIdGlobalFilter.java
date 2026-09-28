package com.tutict.finalassignmentcloud.gateway;

import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.cloud.gateway.filter.headers.HttpHeadersFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
public class TraceIdGlobalFilter implements GlobalFilter, Ordered {

    static final String HEADER = "X-Trace-Id";
    private static final Logger log = LoggerFactory.getLogger(TraceIdGlobalFilter.class);

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String incoming = exchange.getRequest().getHeaders().getFirst(HEADER);
        final String traceId = incoming == null || incoming.isBlank()
                ? UUID.randomUUID().toString().replace("-", "")
                : incoming;
        exchange.getAttributes().put(HEADER, traceId);
        ServerHttpRequest request = exchange.getRequest().mutate().headers(headers -> headers.set(HEADER, traceId)).build();
        String method = request.getMethod() == null ? "GET" : request.getMethod().name();
        String path = request.getPath().value();
        return chain.filter(exchange.mutate().request(request).build())
                .doFinally(signal -> logCompleted(traceId, method, path, exchange));
    }

    private static void logCompleted(String traceId, String method, String path, ServerWebExchange exchange) {
        HttpStatusCode status = exchange.getResponse().getStatusCode();
        int code = status == null ? 0 : status.value();
        if (code < 400) {
            return;
        }
        MDC.put("traceId", traceId);
        try {
            log.info("{} {} -> {}", method, path, code);
        } finally {
            MDC.remove("traceId");
        }
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }
}

@Component
class TraceIdResponseHeadersFilter implements HttpHeadersFilter {

    @Override
    public HttpHeaders filter(HttpHeaders input, ServerWebExchange exchange) {
        Object value = exchange.getAttribute(TraceIdGlobalFilter.HEADER);
        if (value instanceof String traceId && !traceId.isBlank()) {
            input.set(TraceIdGlobalFilter.HEADER, traceId);
        }
        return input;
    }

    @Override
    public boolean supports(Type type) {
        return type == Type.RESPONSE;
    }
}
