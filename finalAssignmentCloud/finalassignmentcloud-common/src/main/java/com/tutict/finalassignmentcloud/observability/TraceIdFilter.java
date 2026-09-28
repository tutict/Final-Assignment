package com.tutict.finalassignmentcloud.observability;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class TraceIdFilter implements Filter {

    private static final Logger log = LoggerFactory.getLogger(TraceIdFilter.class);

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        String traceId = request.getHeader(TraceContext.TRACE_ID_HEADER);
        if (!TraceContext.hasText(traceId)) {
            traceId = TraceContext.newTraceId();
        }

        TraceContext.put(traceId);
        response.setHeader(TraceContext.TRACE_ID_HEADER, traceId);
        try {
            chain.doFilter(req, res);
        } finally {
            if (response.getStatus() >= 400) {
                log.info("{} {} -> {}", request.getMethod(), request.getRequestURI(), response.getStatus());
            }
            TraceContext.clear();
        }
    }
}
