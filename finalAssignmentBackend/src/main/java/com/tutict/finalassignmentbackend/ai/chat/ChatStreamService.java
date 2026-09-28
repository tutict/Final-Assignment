package com.tutict.finalassignmentbackend.ai.chat;

import com.tutict.finalassignmentbackend.ai.provider.AiProviderRegistry;
import com.tutict.finalassignmentbackend.ai.provider.AiToken;
import com.tutict.finalassignmentbackend.reliability.ModelCallBulkhead;
import com.tutict.finalassignmentbackend.reliability.ReliabilityMetrics;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
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
    private final ReliabilityMetrics metrics;

    public ChatStreamService(
            AiProviderRegistry aiProviderRegistry,
            Duration keepAliveInterval
    ) {
        this(aiProviderRegistry, keepAliveInterval, new ModelCallBulkhead(), (ReliabilityMetrics) null);
    }

    @Autowired
    public ChatStreamService(
            AiProviderRegistry aiProviderRegistry,
            @Value("${ai.chat.stream.keepalive:PT15S}") Duration keepAliveInterval,
            ModelCallBulkhead modelCalls,
            ObjectProvider<ReliabilityMetrics> metrics
    ) {
        this(aiProviderRegistry, keepAliveInterval, modelCalls, metrics == null ? (ReliabilityMetrics) null : metrics.getIfAvailable());
    }

    ChatStreamService(
            AiProviderRegistry aiProviderRegistry,
            Duration keepAliveInterval,
            ModelCallBulkhead modelCalls,
            ReliabilityMetrics metrics
    ) {
        this.aiProviderRegistry = aiProviderRegistry;
        this.keepAliveInterval = keepAliveInterval;
        this.modelCalls = modelCalls == null ? new ModelCallBulkhead() : modelCalls;
        this.metrics = metrics;
    }

    public Flux<ChatStreamEvent> stream(AiChatStreamRequest request) {
        String sessionKey = Optional.ofNullable(request.sessionKey())
                .filter(value -> !value.isBlank())
                .orElseGet(() -> UUID.randomUUID().toString());
        String messageId = UUID.randomUUID().toString();

        return Flux.defer(() -> {
            if (!modelCalls.tryAcquire()) {
                markAiFallback();
                return bulkheadFallback(sessionKey, messageId);
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
                ))
                .doFinally(signal -> modelCalls.release());

            return ChatStreamKeepAlive.attach(providerEvents, sessionKey, messageId, keepAliveInterval)
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
        });
    }

    private Flux<ChatStreamEvent> bulkheadFallback(String sessionKey, String messageId) {
        return Flux.just(
                new ChatStreamEvent(
                        ChatStreamEventType.TOKEN.wireName(),
                        sessionKey,
                        messageId,
                        "AI 暂时不可用，请稍后再试。",
                        Map.of("isFallback", true, "reason", "bulkhead_full"),
                        java.time.Instant.now()
                ),
                new ChatStreamEvent(
                        ChatStreamEventType.DONE.wireName(),
                        sessionKey,
                        messageId,
                        null,
                        Map.of("isFallback", true, "reason", "bulkhead_full"),
                        java.time.Instant.now()
                )
        );
    }

    private void markAiFallback() {
        if (metrics != null) {
            metrics.aiFallback();
        }
    }

    private Flux<ChatStreamEvent> toStreamEvents(AiToken token, String sessionKey, String messageId) {
        if (token.metadata() != null && token.metadata().containsKey("queue")) {
            Object raw = token.metadata().get("queue");
            int position = 1;
            if (raw instanceof java.util.Map<?, ?> map) {
                Object value = map.get("position");
                if (value instanceof Number number) {
                    position = Math.max(1, number.intValue());
                }
            }
            return Flux.just(ChatStreamEvent.queue(sessionKey, messageId, position));
        }
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

    private boolean isTerminalEvent(ChatStreamEvent event) {
        return ChatStreamEventType.DONE.wireName().equals(event.type())
                || ChatStreamEventType.ERROR.wireName().equals(event.type());
    }

    private ChatStreamEvent toErrorEvent(String sessionKey, String messageId, Throwable error) {
        String message = error instanceof AiQueueException && error.getMessage() != null && !error.getMessage().isBlank()
                ? error.getMessage()
                : "AI stream failed";
        logger.warn(
                "AI chat stream failed. sessionKey={}, messageId={}, reason={}",
                sessionKey,
                messageId,
                error.toString()
        );
        markAiFallback();
        return ChatStreamEvent.error(sessionKey, messageId, message);
    }
}
