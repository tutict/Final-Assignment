package com.tutict.finalassignmentbackend.ai.chat;

import org.junit.jupiter.api.Test;
import reactor.core.Disposable;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.assertj.core.api.Assertions.assertThat;

class MockAiProviderTest {

    @Test
    void streamsTokensThenDoneInOrder() {
        MockAiProvider provider = new MockAiProvider(
                List.of("你好", "，我", "是"),
                Duration.ofMillis(1),
                Duration.ofMillis(1)
        );

        List<ChatStreamEvent> events = provider.stream(
                        new AiChatStreamRequest("hello", "session-1", Map.of()),
                        "session-1",
                        "message-1"
                )
                .collectList()
                .block(Duration.ofSeconds(1));

        assertThat(events).hasSize(4);
        assertThat(events.get(0)).matches(event -> isToken(event, "你好"));
        assertThat(events.get(1)).matches(event -> isToken(event, "，我"));
        assertThat(events.get(2)).matches(event -> isToken(event, "是"));
        assertThat(events.get(3).type()).isEqualTo(ChatStreamEventType.DONE.wireName());
    }

    @Test
    void cancellationPropagatesToProviderFlux() {
        MockAiProvider provider = new MockAiProvider(
                List.of("first", "second", "third"),
                Duration.ofMillis(1),
                Duration.ofMillis(1)
        );
        AtomicBoolean canceled = new AtomicBoolean(false);

        Disposable subscription = provider.stream(
                                new AiChatStreamRequest("hello", "session-1", Map.of()),
                                "session-1",
                                "message-1"
                        )
                .doOnCancel(() -> canceled.set(true))
                .subscribe();
        subscription.dispose();

        assertThat(canceled).isTrue();
    }

    private boolean isToken(ChatStreamEvent event, String token) {
        return ChatStreamEventType.TOKEN.wireName().equals(event.type())
                && token.equals(event.token())
                && "session-1".equals(event.sessionKey())
                && "message-1".equals(event.messageId());
    }
}
