package com.tutict.finalassignmentcloud.observability;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 15)
public class ResponseResultFilter extends OncePerRequestFilter {

    private final Counter http2xx;
    private final Counter http4xx;
    private final Counter http5xx;

    public ResponseResultFilter(ObjectProvider<MeterRegistry> meters) {
        MeterRegistry registry = meters.getIfAvailable();
        if (registry == null) {
            this.http2xx = null;
            this.http4xx = null;
            this.http5xx = null;
            return;
        }
        this.http2xx = Counter.builder("http_responses_2xx_total").register(registry);
        this.http4xx = Counter.builder("http_responses_4xx_total").register(registry);
        this.http5xx = Counter.builder("http_responses_5xx_total").register(registry);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        chain.doFilter(request, response);
        if (Boolean.TRUE.equals(request.getAttribute(PoolLoadShedFilter.HANDLED))) {
            return;
        }
        note(response.getStatus());
    }

    private void note(int status) {
        if (status >= 200 && status < 300 && http2xx != null) {
            http2xx.increment();
        } else if (status >= 400 && status < 500 && http4xx != null) {
            http4xx.increment();
        } else if (status >= 500 && status < 600 && http5xx != null) {
            http5xx.increment();
        }
    }
}
