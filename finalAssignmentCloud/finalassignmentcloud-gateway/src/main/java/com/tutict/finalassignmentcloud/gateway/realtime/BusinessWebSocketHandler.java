package com.tutict.finalassignmentcloud.gateway.realtime;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.socket.WebSocketHandler;
import org.springframework.web.reactive.socket.WebSocketMessage;
import org.springframework.web.reactive.socket.WebSocketSession;
import reactor.core.publisher.Mono;
import reactor.core.publisher.Sinks;

import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;

/**
 * 业务事件 WebSocket 端点。
 *
 * 维护「用户名 -> 会话集合」的注册表，把 traffic 服务发布的状态变更事件
 * 推送给对应用户。事件载荷是扁平 JSON，与 Flutter / React 端的解析保持一致。
 */
@Component
public class BusinessWebSocketHandler implements WebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(BusinessWebSocketHandler.class);

    private final Map<String, Set<Session>> sessionsByUsername = new ConcurrentHashMap<>();

    @Override
    public Mono<Void> handle(WebSocketSession session) {
        return session.getHandshakeInfo().getPrincipal()
                .ofType(WsPrincipal.class)
                .switchIfEmpty(Mono.error(new IllegalStateException("WebSocket session has no principal")))
                .flatMap(principal -> {
                    Session holder = open(principal.getName(), session);
                    return session.receive()
                            .doOnNext(message -> handleInbound(holder, message))
                            .then()
                            .doFinally(signal -> close(holder));
                });
    }

    public void pushToUser(String username, String payload) {
        if (username == null || username.isBlank()) {
            broadcast(payload);
            return;
        }
        Set<Session> sessions = sessionsByUsername.get(username);
        if (sessions == null || sessions.isEmpty()) {
            return;
        }
        sessions.forEach(session -> session.send(payload));
    }

    public void broadcast(String payload) {
        sessionsByUsername.values().stream()
                .flatMap(Set::stream)
                .forEach(session -> session.send(payload));
    }

    public int activeSessionCount() {
        return sessionsByUsername.values().stream().mapToInt(Set::size).sum();
    }

    private void handleInbound(Session holder, WebSocketMessage message) {
        if (message.getType() == WebSocketMessage.Type.TEXT) {
            // 前端只消费服务端推送的事件，收到客户端消息无需处理。
            log.debug("Ignoring inbound WebSocket message for user={}", holder.username);
        }
    }

    private Session open(String username, WebSocketSession session) {
        Session holder = new Session(username, session);
        sessionsByUsername
                .computeIfAbsent(username, ignored -> new CopyOnWriteArraySet<>())
                .add(holder);
        // 单一订阅 + concatMap 保证同一会话的帧按序发送，不会交错。
        holder.outbound.asFlux()
                .concatMap(message -> session.send(Mono.just(message)))
                .subscribe(null, error -> log.warn("WebSocket send failed for user={}", username, error));
        log.info("WebSocket session registered for user={}, activeSessions={}",
                username, activeSessionCount());
        return holder;
    }

    private void close(Session holder) {
        Set<Session> sessions = sessionsByUsername.get(holder.username);
        if (sessions == null) {
            return;
        }
        sessions.remove(holder);
        if (sessions.isEmpty()) {
            sessionsByUsername.remove(holder.username);
        }
        holder.outbound.tryEmitComplete();
        log.info("WebSocket session closed for user={}, activeSessions={}",
                holder.username, activeSessionCount());
    }

    private static final class Session {

        private final String username;
        private final WebSocketSession session;
        private final Sinks.Many<WebSocketMessage> outbound =
                Sinks.many().unicast().onBackpressureBuffer();

        private Session(String username, WebSocketSession session) {
            this.username = username;
            this.session = session;
        }

        private void send(String payload) {
            if (!session.isOpen()) {
                return;
            }
            Sinks.EmitResult result = outbound.tryEmitNext(session.textMessage(payload));
            if (result.isFailure()) {
                log.warn("Dropped WebSocket event for user={}, reason={}", username, result);
            }
        }
    }
}
