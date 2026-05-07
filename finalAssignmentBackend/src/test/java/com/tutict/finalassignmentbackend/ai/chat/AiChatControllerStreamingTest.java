package com.tutict.finalassignmentbackend.ai.chat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.Disposable;
import reactor.core.publisher.Flux;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AiChatControllerStreamingTest {

    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @Test
    void streamsTypedSseTokenTokenDone() {
        AiStreamProvider provider = (request, sessionKey, messageId) -> Flux.just(
                ChatStreamEvent.token(sessionKey, messageId, "你好"),
                ChatStreamEvent.token(sessionKey, messageId, "Mock"),
                ChatStreamEvent.done(sessionKey, messageId)
        );
        AiChatController controller = controller(provider, Duration.ofSeconds(5), Duration.ofSeconds(15), true);

        List<ServerSentEvent<String>> events = controller.stream(
                        new AiChatStreamRequest("hello", "session-1", Map.of())
                )
                .collectList()
                .block(Duration.ofSeconds(1));

        assertThat(events).hasSize(3);
        assertSse(events.get(0), "token", "你好");
        assertSse(events.get(1), "token", "Mock");
        assertSse(events.get(2), "done", null);
    }

    @Test
    void rejectsWhenStreamingFeatureFlagIsDisabled() {
        AiStreamProvider provider = (request, sessionKey, messageId) -> Flux.empty();
        AiChatController controller = controller(provider, Duration.ofSeconds(5), Duration.ofSeconds(15), false);

        assertThatThrownBy(() -> controller.stream(new AiChatStreamRequest("hello", null, Map.of())))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("AI chat streaming is disabled");
    }

    @Test
    void emitsKeepaliveWhenProviderIsIdle() {
        AiStreamProvider provider = (request, sessionKey, messageId) -> Flux.never();
        ChatStreamService service = new ChatStreamService(
                provider,
                Duration.ofSeconds(60),
                Duration.ofMillis(10)
        );

        ChatStreamEvent event = service.stream(new AiChatStreamRequest("hello", "session-1", Map.of()))
                .blockFirst(Duration.ofMillis(200));

        assertThat(event).isNotNull();
        assertThat(event.type()).isEqualTo(ChatStreamEventType.KEEPALIVE.wireName());
    }

    @Test
    void emitsErrorAndCompletesOnTimeout() {
        AiStreamProvider provider = (request, sessionKey, messageId) -> Flux.never();
        ChatStreamService service = new ChatStreamService(
                provider,
                Duration.ofMillis(10),
                Duration.ofSeconds(60)
        );

        List<ChatStreamEvent> events = service.stream(new AiChatStreamRequest("hello", "session-1", Map.of()))
                .collectList()
                .block(Duration.ofMillis(200));

        assertThat(events).hasSize(1);
        assertThat(events.getFirst().type()).isEqualTo(ChatStreamEventType.ERROR.wireName());
        assertThat(events.getFirst().payload().toString()).contains("AI stream timed out");
    }

    @Test
    void cancellationPropagatesToProvider() throws InterruptedException {
        AtomicBoolean canceled = new AtomicBoolean(false);
        CountDownLatch firstEvent = new CountDownLatch(1);
        AiStreamProvider provider = (request, sessionKey, messageId) -> Flux.interval(Duration.ofSeconds(1))
                .map(index -> ChatStreamEvent.token(sessionKey, messageId, "token-" + index))
                .doOnCancel(() -> canceled.set(true));
        ChatStreamService service = new ChatStreamService(
                provider,
                Duration.ofSeconds(60),
                Duration.ofSeconds(15)
        );

        Disposable subscription = service.stream(new AiChatStreamRequest("hello", "session-1", Map.of()))
                .subscribe(event -> firstEvent.countDown());
        assertThat(firstEvent.await(1500, TimeUnit.MILLISECONDS)).isTrue();
        subscription.dispose();

        assertThat(canceled).isTrue();
    }

    private AiChatController controller(
            AiStreamProvider provider,
            Duration timeout,
            Duration keepAlive,
            boolean enabled
    ) {
        ChatStreamService streamService = new ChatStreamService(provider, timeout, keepAlive);
        AiChatService chatService = new AiChatService(streamService);
        StreamEventWriter writer = new StreamEventWriter(objectMapper);
        return new AiChatController(chatService, writer, enabled);
    }

    private void assertSse(ServerSentEvent<String> sse, String eventName, String token) {
        try {
            JsonNode data = objectMapper.readTree(sse.data());
            assertThat(sse.event()).isEqualTo(eventName);
            assertThat(data.get("type").asText()).isEqualTo(eventName);
            assertThat(data.get("sessionKey").asText()).isEqualTo("session-1");
            if (token == null) {
                assertThat(data.get("token").isNull()).isTrue();
            } else {
                assertThat(data.get("token").asText()).isEqualTo(token);
            }
        } catch (Exception ex) {
            throw new AssertionError("Invalid SSE data: " + sse.data(), ex);
        }
    }
}
