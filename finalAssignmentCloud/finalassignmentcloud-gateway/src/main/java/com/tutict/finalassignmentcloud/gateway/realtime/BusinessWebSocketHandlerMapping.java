package com.tutict.finalassignmentcloud.gateway.realtime;

import org.springframework.core.Ordered;
import org.springframework.web.reactive.HandlerMapping;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

/**
 * 将业务事件 WebSocket 端点映射到处理器。
 *
 * Spring Framework 7 移除了 WebSocketHandlerMapping，而网关的
 * SimpleUrlHandlerMappingGlobalCorsAutoConfiguration 要求上下文中只有一个
 * SimpleUrlHandlerMapping，因此这里直接实现 HandlerMapping，而不是再注册一个
 * SimpleUrlHandlerMapping。
 */
public class BusinessWebSocketHandlerMapping implements HandlerMapping, Ordered {

    private final Object handler;
    private final int order;

    public BusinessWebSocketHandlerMapping(Object handler, int order) {
        this.handler = handler;
        this.order = order;
    }

    @Override
    public Mono<Object> getHandler(ServerWebExchange exchange) {
        if (!WsTicketHandshakeFilter.PATH.equals(exchange.getRequest().getPath().value())) {
            return Mono.empty();
        }
        return Mono.just(handler);
    }

    @Override
    public int getOrder() {
        return order;
    }
}
