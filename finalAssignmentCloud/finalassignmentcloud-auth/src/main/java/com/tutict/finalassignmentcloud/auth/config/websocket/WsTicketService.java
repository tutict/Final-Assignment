package com.tutict.finalassignmentcloud.auth.config.websocket;

import com.tutict.finalassignmentcloud.common.realtime.WsTicketStore;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

/**
 * 签发 WebSocket 连接票据。
 *
 * 票据保存在 Redis 中，由网关在握手时一次性消费，
 * 因此认证服务与网关无需共享进程内状态。
 */
@Service
public class WsTicketService {

    private final WsTicketStore wsTicketStore;

    public WsTicketService(WsTicketStore wsTicketStore) {
        this.wsTicketStore = wsTicketStore;
    }

    public Ticket issue(String username, List<String> roles) {
        WsTicketStore.IssuedTicket issued = wsTicketStore.issue(username, roles);
        return new Ticket(issued.value(), issued.username(), issued.roles(), issued.expiresAt());
    }

    public record Ticket(String value, String username, List<String> roles, Instant expiresAt) {
    }
}
