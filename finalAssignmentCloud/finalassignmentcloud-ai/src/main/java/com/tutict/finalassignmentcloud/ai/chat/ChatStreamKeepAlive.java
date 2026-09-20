package com.tutict.finalassignmentcloud.ai.chat;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Duration;

public final class ChatStreamKeepAlive {

    private ChatStreamKeepAlive() {
    }

    public static Flux<ChatStreamEvent> attach(
            Flux<ChatStreamEvent> source,
            String sessionKey,
            String messageId,
            Duration interval
    ) {
        Duration keepAliveInterval = interval == null || interval.isNegative() || interval.isZero()
                ? Duration.ofSeconds(15)
                : interval;
        return source.publish(shared -> {
            Flux<Long> resetSignals = Flux.concat(
                    Mono.just(0L),
                    shared.filter(event -> !ChatStreamEventType.KEEPALIVE.wireName().equals(event.type()))
                            .map(ignored -> 0L)
            );
            Flux<ChatStreamEvent> keepAlives = resetSignals
                    .switchMap(ignored -> Flux.interval(keepAliveInterval)
                            .map(tick -> ChatStreamEvent.keepalive(sessionKey, messageId)))
                    .takeUntilOther(shared.then());
            return Flux.merge(shared, keepAlives);
        });
    }
}
