package com.tutict.finalassignmentbackend.ai.chat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.ai.provider.AiChatPrompt;
import com.tutict.finalassignmentbackend.ai.provider.AiGenerationOptions;
import com.tutict.finalassignmentbackend.ai.provider.AiMessage;
import com.tutict.finalassignmentbackend.ai.provider.AiProvider;
import com.tutict.finalassignmentbackend.ai.provider.AiProviderProperties;
import com.tutict.finalassignmentbackend.ai.provider.AiProviderRegistry;
import com.tutict.finalassignmentbackend.ai.provider.AiToken;
import com.tutict.finalassignmentbackend.ai.provider.NoopAiProvider;
import com.tutict.finalassignmentbackend.ai.provider.ProviderHealth;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import com.tutict.finalassignmentbackend.service.ChatAgent;
import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;
import org.springframework.http.codec.ServerSentEvent;
import reactor.core.Disposable;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

class AiChatControllerStreamingTest {

    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @Test
    void streamsTypedSseTokenTokenDone() {
        AiProvider provider = provider("primary", Flux.just(
                new AiToken("你好", false, Map.of()),
                new AiToken("Mock", false, Map.of()),
                new AiToken("", true, Map.of())
        ));
        AiChatController controller = controller(provider, Duration.ofSeconds(5), Duration.ofSeconds(15), true);

        ResponseEntity<?> response = controller.stream(new AiChatStreamRequest("hello", "session-1", Map.of()));
        assertThat(response.getStatusCode().value()).isEqualTo(200);

        List<ServerSentEvent<String>> events = responseStream(response)
                .collectList()
                .block(Duration.ofSeconds(1));

        assertThat(events).hasSize(3);
        assertSse(events.get(0), "token", "你好");
        assertSse(events.get(1), "token", "Mock");
        assertSse(events.get(2), "done", null);
    }

    @Test
    void rejectsWhenStreamingFeatureFlagIsDisabled() {
        AiChatController controller = controller(
                provider("primary", Flux.empty()),
                Duration.ofSeconds(5),
                Duration.ofSeconds(15),
                false
        );

        ResponseEntity<?> response = controller.stream(new AiChatStreamRequest("hello", null, Map.of()));

        assertThat(response.getStatusCode().value()).isEqualTo(503);
        assertThat(response.getBody()).isInstanceOf(ApiResponse.class);
        ApiResponse<?> body = (ApiResponse<?>) response.getBody();
        assertThat(body.isSuccess()).isFalse();
        assertThat(body.getErrorCode()).isEqualTo("SERVICE_UNAVAILABLE");
        assertThat(body.getMessage()).isEqualTo("AI \u6d41\u5f0f\u670d\u52a1\u6682\u672a\u542f\u7528");
    }

    @Test
    void emitsKeepaliveWhenProviderIsIdle() {
        ChatStreamService service = service(
                provider("primary", Flux.never()),
                Duration.ofSeconds(5),
                Duration.ofMillis(10)
        );

        ChatStreamEvent event = service.stream(new AiChatStreamRequest("hello", "session-1", Map.of()))
                .blockFirst(Duration.ofMillis(200));

        assertThat(event).isNotNull();
        assertThat(event.type()).isEqualTo(ChatStreamEventType.KEEPALIVE.wireName());
    }

    @Test
    void fallsBackOnProviderTimeout() {
        AiProvider primary = provider("primary", Flux.never());
        AiProvider fallback = provider("fallback", Flux.just(
                new AiToken("fallback", false, Map.of()),
                new AiToken("", true, Map.of())
        ));
        ChatStreamService service = service(
                List.of(primary, fallback),
                "primary",
                "fallback",
                Duration.ofMillis(10),
                Duration.ofSeconds(60)
        );

        List<ChatStreamEvent> events = service.stream(new AiChatStreamRequest("hello", "session-1", Map.of()))
                .collectList()
                .block(Duration.ofMillis(500));

        assertThat(events).hasSize(2);
        assertThat(events.get(0).type()).isEqualTo(ChatStreamEventType.TOKEN.wireName());
        assertThat(events.get(0).token()).isEqualTo("fallback");
        assertThat(events.get(0).payload().toString()).contains("provider=fallback");
        assertThat(events.get(1).type()).isEqualTo(ChatStreamEventType.DONE.wireName());
    }

    @Test
    void cancellationPropagatesToProvider() throws InterruptedException {
        AtomicBoolean canceled = new AtomicBoolean(false);
        CountDownLatch firstEvent = new CountDownLatch(1);
        AiProvider primary = provider(
                "primary",
                Flux.interval(Duration.ofMillis(10))
                        .map(index -> new AiToken("token-" + index, false, Map.of()))
                        .doOnCancel(() -> canceled.set(true))
        );
        ChatStreamService service = service(primary, Duration.ofSeconds(5), Duration.ofSeconds(15));

        Disposable subscription = service.stream(new AiChatStreamRequest("hello", "session-1", Map.of()))
                .subscribe(event -> firstEvent.countDown());
        assertThat(firstEvent.await(500, TimeUnit.MILLISECONDS)).isTrue();
        subscription.dispose();

        assertThat(canceled).isTrue();
    }

    private AiChatController controller(
            AiProvider provider,
            Duration streamingTimeout,
            Duration keepAlive,
            boolean enabled
    ) {
        ChatStreamService streamService = service(provider, streamingTimeout, keepAlive);
        AiChatService chatService = new AiChatService(streamService);
        StreamEventWriter writer = new StreamEventWriter(objectMapper);
        return new AiChatController(chatService, writer, mock(ChatAgent.class), enabled);
    }

    private ChatStreamService service(AiProvider provider, Duration streamingTimeout, Duration keepAlive) {
        return service(List.of(provider), provider.providerName(), "noop", streamingTimeout, keepAlive);
    }

    private ChatStreamService service(
            List<AiProvider> providers,
            String primary,
            String fallback,
            Duration streamingTimeout,
            Duration keepAlive
    ) {
        AiProviderProperties properties = new AiProviderProperties();
        properties.getProvider().setPrimary(primary);
        properties.getProvider().setFallback(fallback);
        properties.getProvider().setStreamingTimeout(streamingTimeout);
        properties.getProvider().setRetryAttempts(0);
        AiProviderRegistry registry = new AiProviderRegistry(
                Flux.concat(Flux.fromIterable(providers), Flux.just(new NoopAiProvider())).collectList().block(),
                properties
        );
        return new ChatStreamService(registry, keepAlive);
    }

    private AiProvider provider(String name, Flux<AiToken> stream) {
        return new AiProvider() {
            @Override
            public String providerName() {
                return name;
            }

            @Override
            public boolean supportsStreaming() {
                return true;
            }

            @Override
            public Flux<AiToken> stream(AiChatPrompt prompt, AiGenerationOptions options) {
                return stream;
            }

            @Override
            public Mono<AiMessage> complete(AiChatPrompt prompt, AiGenerationOptions options) {
                return Mono.just(new AiMessage("", Map.of()));
            }

            @Override
            public Mono<ProviderHealth> health() {
                return Mono.just(ProviderHealth.up(name));
            }
        };
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

    @SuppressWarnings("unchecked")
    private Flux<ServerSentEvent<String>> responseStream(ResponseEntity<?> response) {
        assertThat(response.getBody()).isInstanceOf(Flux.class);
        return (Flux<ServerSentEvent<String>>) response.getBody();
    }
}
