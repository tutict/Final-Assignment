package com.tutict.finalassignmentcloud.gateway;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;
import reactor.core.publisher.SignalType;

@Component
public class GatewayResponseMetrics implements GlobalFilter, Ordered {

    private final Counter http2xx;
    private final Counter http4xx;
    private final Counter http5xx;

    public GatewayResponseMetrics(MeterRegistry registry) {
        this.http2xx = Counter.builder("http_responses_2xx_total").register(registry);
        this.http4xx = Counter.builder("http_responses_4xx_total").register(registry);
        this.http5xx = Counter.builder("http_responses_5xx_total").register(registry);
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        return chain.filter(exchange).doFinally(signal -> note(status(exchange, signal)));
    }

    private static int status(ServerWebExchange exchange, SignalType signal) {
        HttpStatusCode code = exchange.getResponse().getStatusCode();
        if (code == null) {
            return signal == SignalType.ON_ERROR ? 500 : 0;
        }
        if (signal == SignalType.ON_ERROR && code.is2xxSuccessful()) {
            return 500;
        }
        return code.value();
    }

    private void note(int status) {
        if (status >= 200 && status < 300) {
            http2xx.increment();
        } else if (status >= 400 && status < 500) {
            http4xx.increment();
        } else if (status >= 500 && status < 600) {
            http5xx.increment();
        }
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE + 5;
    }
}