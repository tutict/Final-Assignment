package com.tutict.finalassignmentcloud.gateway;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.core.io.buffer.DataBufferUtils;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpRequestDecorator;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Component
public class LoginRateLimitGlobalFilter implements GlobalFilter, Ordered {

    static final int MAX_ACCOUNT_PER_MINUTE = 8;
    static final int MAX_IP_PER_MINUTE = 40;
    static final long LOCK_MILLIS = 120_000L;
    private static final ObjectMapper JSON = new ObjectMapper();

    private final Map<String, Window> accounts = new ConcurrentHashMap<>();
    private final Map<String, Window> ips = new ConcurrentHashMap<>();

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getURI().getPath();
        if (!HttpMethod.POST.equals(exchange.getRequest().getMethod()) || !"/api/auth/login".equals(path)) {
            return chain.filter(exchange);
        }
        return DataBufferUtils.join(exchange.getRequest().getBody())
                .defaultIfEmpty(exchange.getResponse().bufferFactory().wrap(new byte[0]))
                .flatMap(buffer -> {
                    byte[] bytes = new byte[buffer.readableByteCount()];
                    buffer.read(bytes);
                    DataBufferUtils.release(buffer);
                    String username = username(bytes);
                    String ip = remoteIp(exchange);
                    long retry = reserve(username, ip);
                    if (retry > 0) {
                        return reject(exchange, retry);
                    }
                    ServerHttpRequest decorated = new ServerHttpRequestDecorator(exchange.getRequest()) {
                        @Override
                        public Flux<DataBuffer> getBody() {
                            return Flux.just(exchange.getResponse().bufferFactory().wrap(bytes));
                        }
                    };
                    return chain.filter(exchange.mutate().request(decorated).build());
                });
    }

    long reserve(String username, String ip) {
        if (username != null && !username.isBlank()) {
            long accountRetry = reserve(accounts, "account:" + username, MAX_ACCOUNT_PER_MINUTE);
            if (accountRetry > 0) {
                return accountRetry;
            }
        }
        return reserve(ips, "ip:" + ip, MAX_IP_PER_MINUTE);
    }

    private long reserve(Map<String, Window> buckets, String key, int limit) {
        long now = Instant.now().toEpochMilli();
        Window window = buckets.computeIfAbsent(key, ignored -> new Window());
        synchronized (window) {
            if (window.lockedUntil > now) {
                return Math.max(1L, (long) Math.ceil((window.lockedUntil - now) / 1000.0));
            }
            while (!window.stamps.isEmpty() && now - window.stamps.peekFirst() > 60_000L) {
                window.stamps.removeFirst();
            }
            if (window.stamps.size() >= limit) {
                window.lockedUntil = now + LOCK_MILLIS;
                window.stamps.clear();
                return LOCK_MILLIS / 1000L;
            }
            window.stamps.addLast(now);
            return 0L;
        }
    }

    private Mono<Void> reject(ServerWebExchange exchange, long retryAfter) {
        exchange.getResponse().setStatusCode(HttpStatus.TOO_MANY_REQUESTS);
        exchange.getResponse().getHeaders().set(HttpHeaders.RETRY_AFTER, Long.toString(retryAfter));
        exchange.getResponse().getHeaders().setContentType(MediaType.APPLICATION_JSON);
        byte[] body = ("{\"success\":false,\"errorCode\":\"LOGIN_RATE_LIMITED\",\"retryAfterSeconds\":" + retryAfter + "}")
                .getBytes(StandardCharsets.UTF_8);
        DataBuffer buffer = exchange.getResponse().bufferFactory().wrap(body);
        return exchange.getResponse().writeWith(Mono.just(buffer));
    }

    private static String username(byte[] body) {
        try {
            JsonNode node = JSON.readTree(body);
            String username = node.path("username").asText("");
            return username == null ? "" : username.trim().toLowerCase(Locale.ROOT);
        } catch (Exception ex) {
            return "";
        }
    }

    private static String remoteIp(ServerWebExchange exchange) {
        if (exchange.getRequest().getRemoteAddress() == null
                || exchange.getRequest().getRemoteAddress().getAddress() == null) {
            return "unknown";
        }
        return exchange.getRequest().getRemoteAddress().getAddress().getHostAddress();
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE + 10;
    }

    private static final class Window {
        private final Deque<Long> stamps = new ArrayDeque<>();
        private long lockedUntil;
    }
}