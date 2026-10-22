package com.tutict.finalassignmentcloud.common.realtime;

import java.time.Duration;

/**
 * 业务实时事件的跨服务契约。
 *
 * 认证服务把 WebSocket 票据写入 Redis，网关在握手时一次性消费；
 * 各业务服务把状态变更事件发布到 Redis 频道，网关订阅后推送给目标用户的会话。
 * 契约放在 common 模块，保证签发方与消费方使用同一套键名与频道名。
 */
public final class BusinessEventBus {

    public static final String TICKET_KEY_PREFIX = "finalassignment:ws-ticket:";
    public static final String EVENT_CHANNEL = "finalassignment:business-events";
    public static final Duration TICKET_TTL = Duration.ofSeconds(30);

    private BusinessEventBus() {
    }

    public static String ticketKey(String ticket) {
        return TICKET_KEY_PREFIX + ticket;
    }
}
