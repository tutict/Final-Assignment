package com.tutict.finalassignmentcloud.common.realtime;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.Objects;

/**
 * WebSocket 票据承载的调用方身份。
 *
 * 票据本身只是一个随机串，身份保存在 Redis 中，因此网关无需与认证服务共享密钥。
 */
public record WsTicketPayload(String username, List<String> roles) {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    public WsTicketPayload {
        roles = roles == null ? List.of() : roles.stream().filter(Objects::nonNull).toList();
    }

    public String toJson() {
        try {
            return MAPPER.writeValueAsString(this);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Failed to serialize WebSocket ticket payload", ex);
        }
    }

    public static WsTicketPayload fromJson(String json) {
        if (json == null || json.isBlank()) {
            return null;
        }
        try {
            WsTicketPayload payload = MAPPER.readValue(json, WsTicketPayload.class);
            if (payload == null || payload.username() == null || payload.username().isBlank()) {
                return null;
            }
            return payload;
        } catch (JsonProcessingException ex) {
            return null;
        }
    }
}
