package com.tutict.finalassignmentcloud.gateway.realtime;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.Ordered;

/**
 * 注册业务事件 WebSocket 端点。
 *
 * Spring Framework 7 移除了 WebSocketHandlerMapping，这里用自定义的 HandlerMapping
 * 把 /eventbus/websocket 映射到处理器；顺序高于网关的路由匹配，避免请求被当成普通路由处理。
 * WebSocketHandlerAdapter 由 WebFlux 自动配置提供，此处不再重复注册。
 */
@Configuration
public class BusinessWebSocketConfiguration {

    @Bean
    public BusinessWebSocketHandlerMapping businessWebSocketHandlerMapping(BusinessWebSocketHandler handler) {
        return new BusinessWebSocketHandlerMapping(handler, Ordered.HIGHEST_PRECEDENCE + 2);
    }
}
