package com.tutict.finalassignmentcloud.gateway.realtime;

import com.tutict.finalassignmentcloud.common.realtime.WsTicketStore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Locale;

/**
 * WebSocket 握手鉴权。
 *
 * 握手时校验一次性票据（Redis 中存储，GETDEL 消费），校验通过后把身份写入
 * exchange 的 Principal，供 BusinessWebSocketHandler 读取。
 * 校验失败直接返回 401，不会完成协议升级。
 */
@Component
public class WsTicketHandshakeFilter implements WebFilter, Ordered {

    static final String PATH = "/eventbus/websocket";
    static final String TICKET_PARAM = "ws_ticket";

    private static final Logger log = LoggerFactory.getLogger(WsTicketHandshakeFilter.class);

    private final WsTicketStore ticketStore;
    private final List<String> allowedOrigins;

    public WsTicketHandshakeFilter(WsTicketStore ticketStore,
                                   @Value("${app.websocket.allowed-origins:}") List<String> allowedOrigins) {
        this.ticketStore = ticketStore;
        this.allowedOrigins = allowedOrigins == null ? List.of() : allowedOrigins.stream()
                .filter(origin -> origin != null && !origin.isBlank())
                .map(origin -> origin.trim().toLowerCase(Locale.ROOT))
                .toList();
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        if (!PATH.equals(exchange.getRequest().getPath().value())) {
            return chain.filter(exchange);
        }
        if (!isOriginAllowed(exchange.getRequest().getHeaders().getFirst(HttpHeaders.ORIGIN))) {
            return reject(exchange, HttpStatus.FORBIDDEN, "ORIGIN_NOT_ALLOWED", "WebSocket origin is not allowed");
        }
        String ticket = exchange.getRequest().getQueryParams().getFirst(TICKET_PARAM);
        return Mono.fromCallable(() -> ticketStore.consume(ticket))
                .subscribeOn(Schedulers.boundedElastic())
                .onErrorResume(ex -> {
                    log.warn("WebSocket ticket lookup failed", ex);
                    return Mono.error(new TicketLookupException());
                })
                .flatMap(payload -> {
                    if (payload == null) {
                        return reject(exchange, HttpStatus.UNAUTHORIZED, "UNAUTHORIZED",
                                "Missing or invalid WebSocket ticket");
                    }
                    WsPrincipal principal = new WsPrincipal(payload.username(), payload.roles());
                    return chain.filter(exchange.mutate().principal(Mono.just(principal)).build());
                })
                .onErrorResume(TicketLookupException.class,
                        ex -> reject(exchange, HttpStatus.SERVICE_UNAVAILABLE, "WS_TICKET_UNAVAILABLE",
                                "WebSocket ticket service is unavailable"));
    }

    private boolean isOriginAllowed(String origin) {
        if (allowedOrigins.isEmpty() || origin == null || origin.isBlank()) {
            return true;
        }
        return allowedOrigins.contains(origin.trim().toLowerCase(Locale.ROOT));
    }

    private Mono<Void> reject(ServerWebExchange exchange, HttpStatus status, String code, String message) {
        ServerHttpResponse response = exchange.getResponse();
        if (response.isCommitted()) {
            return Mono.error(new IllegalStateException("Response already committed"));
        }
        response.setStatusCode(status);
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        byte[] body = ("{\"success\":false,\"errorCode\":\"" + code + "\",\"message\":\"" + message + "\"}")
                .getBytes(StandardCharsets.UTF_8);
        return response.writeWith(Mono.just(response.bufferFactory().wrap(body)));
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE + 1;
    }

    private static final class TicketLookupException extends RuntimeException {
    }
}
