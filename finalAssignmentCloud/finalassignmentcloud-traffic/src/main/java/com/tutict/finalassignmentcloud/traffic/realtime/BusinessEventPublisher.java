package com.tutict.finalassignmentcloud.traffic.realtime;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.tutict.finalassignmentcloud.common.realtime.BusinessEventBus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * 业务事件发布器。
 *
 * 申诉与缴费状态变更后，把事件发布到 Redis 频道，由网关转发给对应的 WebSocket 会话。
 * 发布失败只记录日志，不影响业务事务本身。
 */
@Service
public class BusinessEventPublisher {

    private static final Logger log = LoggerFactory.getLogger(BusinessEventPublisher.class);

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final StringRedisTemplate redisTemplate;

    public BusinessEventPublisher(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    /**
     * @param target 事件归属的用户名，为空时广播给全部连接
     */
    public void publish(String target, Map<String, Object> event) {
        if (event == null || event.isEmpty()) {
            return;
        }
        try {
            ObjectNode envelope = MAPPER.createObjectNode();
            envelope.put("target", target == null ? "" : target);
            envelope.set("event", MAPPER.valueToTree(event));
            redisTemplate.convertAndSend(BusinessEventBus.EVENT_CHANNEL, MAPPER.writeValueAsString(envelope));
        } catch (Exception ex) {
            log.warn("Failed to publish business event type={}", event.get("type"), ex);
        }
    }
}
