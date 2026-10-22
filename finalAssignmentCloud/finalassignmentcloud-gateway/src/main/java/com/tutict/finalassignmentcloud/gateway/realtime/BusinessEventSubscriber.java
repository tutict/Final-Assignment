package com.tutict.finalassignmentcloud.gateway.realtime;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.common.realtime.BusinessEventBus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.DisposableBean;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.Message;
import org.springframework.data.redis.connection.MessageListener;
import org.springframework.data.redis.listener.ChannelTopic;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;

/**
 * 订阅业务事件频道并转发到 WebSocket 会话。
 *
 * traffic 服务把申诉/缴费状态变更发布到 Redis 频道，网关在这里消费，
 * 再按事件中的 target 推送给对应用户的会话；target 为空时广播给全部会话。
 */
@Component
public class BusinessEventSubscriber implements MessageListener, InitializingBean, DisposableBean {

    private static final Logger log = LoggerFactory.getLogger(BusinessEventSubscriber.class);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final BusinessWebSocketHandler handler;
    private final RedisConnectionFactory connectionFactory;
    private RedisMessageListenerContainer container;

    public BusinessEventSubscriber(BusinessWebSocketHandler handler,
                                   RedisConnectionFactory connectionFactory) {
        this.handler = handler;
        this.connectionFactory = connectionFactory;
    }

    @Override
    public void afterPropertiesSet() throws Exception {
        container = new RedisMessageListenerContainer();
        container.setConnectionFactory(connectionFactory);
        container.addMessageListener(this, new ChannelTopic(BusinessEventBus.EVENT_CHANNEL));
        container.afterPropertiesSet();
        if (!container.isRunning()) {
            container.start();
        }
        log.info("Subscribed to business event channel {}", BusinessEventBus.EVENT_CHANNEL);
    }

    @Override
    public void destroy() throws Exception {
        if (container != null) {
            container.destroy();
        }
    }

    @Override
    public void onMessage(Message message, byte[] pattern) {
        String body = new String(message.getBody(), StandardCharsets.UTF_8);
        try {
            JsonNode root = MAPPER.readTree(body);
            JsonNode event = root.path("event");
            if (event.isMissingNode() || event.isNull()) {
                return;
            }
            String target = root.path("target").asText("");
            handler.pushToUser(target, MAPPER.writeValueAsString(event));
        } catch (Exception ex) {
            log.warn("Failed to dispatch business event payload={}", body, ex);
        }
    }
}
