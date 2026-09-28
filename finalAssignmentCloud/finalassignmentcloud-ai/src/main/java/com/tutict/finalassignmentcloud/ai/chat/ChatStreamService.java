package com.tutict.finalassignmentcloud.ai.chat;

import com.tutict.finalassignmentcloud.ai.provider.AiProviderRegistry;
import com.tutict.finalassignmentcloud.ai.provider.AiToken;
import com.tutict.finalassignmentcloud.ai.reliability.AiFallbackMetrics;
import com.tutict.finalassignmentcloud.ai.reliability.ModelCallBulkhead;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.publisher.BufferOverflowStrategy;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class ChatStreamService {

    private static final Logger logger = LoggerFactory.getLogger(ChatStreamService.class);
    private static final int BACKPRESSURE_BUFFER_SIZE = 256;

    private final AiProviderRegistry aiProviderRegistry;
    private final Duration keepAliveInterval;
    private final ModelCallBulkhead modelCalls;
    private final AiFallbackMetrics aiFallbackMetrics;

    public ChatStreamService(
            AiProviderRegistry aiProviderRegistry,
            Duration keepAliveInterval
    ) {
        this(aiProviderRegistry, keepAliveInterval, new ModelCallBulkhead(), null);
    }

    @Autowired
    public ChatStreamService(
            AiProviderRegistry aiProviderRegistry,
            @Value("${ai.chat.stream.keepalive:PT15S}") Duration keepAliveInterval,
            ModelCallBulkhead modelCalls,
            AiFallbackMetrics aiFallbackMetrics
    ) {
        this.aiProviderRegistry = aiProviderRegistry;
        this.keepAliveInterval = keepAliveInterval;
        this.modelCalls = modelCalls == null ? new ModelCallBulkhead() : modelCalls;
        this.aiFallbackMetrics = aiFallbackMetrics;
    }

    public Flux<ChatStreamEvent> stream(AiChatStreamRequest request) {
        String sessionKey = Optional.ofNullable(request.sessionKey())
                .filter(value -> !value.isBlank())
                .orElseGet(() -> UUID.randomUUID().toString());
        String messageId = UUID.randomUUID().toString();

        return Flux.defer(() -> {
            if (!modelCalls.tryAcquire()) {
                if (aiFallbackMetrics != null) {
                    aiFallbackMetrics.increment();
                }
                return Flux.just(
                        new ChatStreamEvent(
                                ChatStreamEventType.TOKEN.wireName(),
                                sessionKey,
                                messageId,
                                "AI 暂时不可用，请稍后再试。",
                                Map.of("isFallback", true, "reason", "bulkhead_full"),
                                Instant.now()
                        ),
                        new ChatStreamEvent(
                                ChatStreamEventType.DONE.wireName(),
                                sessionKey,
                                messageId,
                                null,
                                Map.of("isFallback", true, "reason", "bulkhead_full"),
                                Instant.now()
                        )
                );
            }
            Flux<ChatStreamEvent> providerEvents = aiProviderRegistry.stream(
                        request.normalizedMessage(),
                        request.metadata()
                )
                .concatMap(token -> toStreamEvents(token, sessionKey, messageId))
                .switchIfEmpty(Flux.just(ChatStreamEvent.done(sessionKey, messageId)))
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
                .doFinally(signal -> modelCalls.release())
                .limitRate(32);
        });
    }

    private Flux<ChatStreamEvent> toStreamEvents(AiToken token, String sessionKey, String messageId) {
        Flux<ChatStreamEvent> events = Flux.empty();
        if (token.text() != null && !token.text().isEmpty()) {
            events = events.concatWithValues(new ChatStreamEvent(
                    ChatStreamEventType.TOKEN.wireName(),
                    sessionKey,
                    messageId,
                    token.text(),
                    token.metadata(),
                    Instant.now()
            ));
        }
        if (token.finished()) {
            events = events.concatWithValues(ChatStreamEvent.done(sessionKey, messageId));
        }
        return events;
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
        String message = "AI stream failed";
        logger.warn(
                "AI chat stream failed. sessionKey={}, messageId={}, reason={}",
                sessionKey,
                messageId,
                error.toString()
        );
        if (aiFallbackMetrics != null) {
            aiFallbackMetrics.increment();
        }
        return ChatStreamEvent.error(sessionKey, messageId, message);
    }
}
