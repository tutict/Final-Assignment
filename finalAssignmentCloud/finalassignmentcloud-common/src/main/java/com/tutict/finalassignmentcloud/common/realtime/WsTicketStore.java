package com.tutict.finalassignmentcloud.common.realtime;

import org.springframework.data.redis.core.StringRedisTemplate;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * 基于 Redis 的 WebSocket 票据存储。
 *
 * 认证服务签发票据并写入 Redis（30 秒有效期），网关在 WebSocket 握手时一次性消费，
 * 因此票据在多实例部署下依然有效，且无法被重放。
 */
public class WsTicketStore {

    private final StringRedisTemplate redisTemplate;

    public WsTicketStore(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    public IssuedTicket issue(String username, List<String> roles) {
        if (username == null || username.isBlank()) {
            throw new IllegalArgumentException("username is required to issue a WebSocket ticket");
        }
        String value = UUID.randomUUID().toString();
        WsTicketPayload payload = new WsTicketPayload(username, roles);
        redisTemplate.opsForValue()
                .set(BusinessEventBus.ticketKey(value), payload.toJson(), BusinessEventBus.TICKET_TTL);
        return new IssuedTicket(value, payload.username(), payload.roles(),
                Instant.now().plus(BusinessEventBus.TICKET_TTL));
    }

    public WsTicketPayload consume(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String json = redisTemplate.opsForValue().getAndDelete(BusinessEventBus.ticketKey(value));
        return WsTicketPayload.fromJson(json);
    }

    public record IssuedTicket(String value, String username, List<String> roles, Instant expiresAt) {
    }
}
