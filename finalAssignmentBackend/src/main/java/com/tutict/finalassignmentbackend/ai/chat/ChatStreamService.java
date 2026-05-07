package com.tutict.finalassignmentbackend.ai.chat;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.publisher.BufferOverflowStrategy;

import java.time.Duration;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.TimeoutException;

@Service
public class ChatStreamService {

    private static final Logger logger = LoggerFactory.getLogger(ChatStreamService.class);
    private static final int BACKPRESSURE_BUFFER_SIZE = 256;

    private final AiStreamProvider aiStreamProvider;
    private final Duration streamTimeout;
    private final Duration keepAliveInterval;

    public ChatStreamService(
            AiStreamProvider aiStreamProvider,
            @Value("${ai.chat.stream.timeout:PT60S}") Duration streamTimeout,
            @Value("${ai.chat.stream.keepalive:PT15S}") Duration keepAliveInterval
    ) {
        this.aiStreamProvider = aiStreamProvider;
        this.streamTimeout = streamTimeout;
        this.keepAliveInterval = keepAliveInterval;
    }

    public Flux<ChatStreamEvent> stream(AiChatStreamRequest request) {
        String sessionKey = Optional.ofNullable(request.sessionKey())
                .filter(value -> !value.isBlank())
                .orElseGet(() -> UUID.randomUUID().toString());
        String messageId = UUID.randomUUID().toString();

        Flux<ChatStreamEvent> providerEvents = aiStreamProvider.stream(request, sessionKey, messageId)
                .timeout(streamTimeout)
                .onErrorResume(error -> Flux.just(toErrorEvent(sessionKey, messageId, error)))
                .takeUntil(this::isTerminalEvent)
                .doOnCancel(() -> logger.info(
                        "AI chat stream canceled. sessionKey={}, messageId={}",
                        sessionKey,
                        messageId
                ));

        return withKeepAlive(providerEvents, sessionKey, messageId)
                .onBackpressureBuffer(
                        BACKPRESSURE_BUFFER_SIZE,
                        dropped -> logger.warn(
                                "Dropped AI stream event under backpressure. type={}, sessionKey={}, messageId={}",
                                dropped.type(),
                                dropped.sessionKey(),
                                dropped.messageId()
                        ),
                        BufferOverflowStrategy.DROP_OLDEST
                )
                .limitRate(32);
    }

    private Flux<ChatStreamEvent> withKeepAlive(
            Flux<ChatStreamEvent> source,
            String sessionKey,
            String messageId
    ) {
        return source.publish(shared -> {
            Flux<Long> resetSignals = Flux.concat(
                    Mono.just(0L),
                    shared.filter(this::resetsKeepAlive).map(ignored -> 0L)
            );
            Flux<ChatStreamEvent> keepAlives = resetSignals
                    .switchMap(ignored -> Flux.interval(keepAliveInterval)
                            .map(tick -> ChatStreamEvent.keepalive(sessionKey, messageId)))
                    .takeUntilOther(shared.then());

            return Flux.merge(shared, keepAlives);
        });
    }

    private boolean resetsKeepAlive(ChatStreamEvent event) {
        return !ChatStreamEventType.KEEPALIVE.wireName().equals(event.type());
    }

    private boolean isTerminalEvent(ChatStreamEvent event) {
        return ChatStreamEventType.DONE.wireName().equals(event.type())
                || ChatStreamEventType.ERROR.wireName().equals(event.type());
    }

    private ChatStreamEvent toErrorEvent(String sessionKey, String messageId, Throwable error) {
        String message = error instanceof TimeoutException
                ? "AI stream timed out"
                : "AI stream failed";
        logger.warn(
                "AI chat stream failed. sessionKey={}, messageId={}, reason={}",
                sessionKey,
                messageId,
                error.toString()
        );
        return ChatStreamEvent.error(sessionKey, messageId, message);
    }
}
