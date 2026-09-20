package com.tutict.finalassignmentbackend.ai.agent;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryOffensesTool;
import com.tutict.finalassignmentbackend.ai.chat.ChatStreamEvent;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.ai.provider.AiChatPrompt;
import com.tutict.finalassignmentbackend.ai.provider.AiGenerationOptions;
import com.tutict.finalassignmentbackend.ai.provider.AiMessage;
import com.tutict.finalassignmentbackend.ai.provider.AiProvider;
import com.tutict.finalassignmentbackend.ai.provider.AiProviderProperties;
import com.tutict.finalassignmentbackend.ai.provider.AiProviderRegistry;
import com.tutict.finalassignmentbackend.ai.provider.AiToken;
import com.tutict.finalassignmentbackend.ai.provider.NoopAiProvider;
import com.tutict.finalassignmentbackend.ai.provider.ProviderHealth;
import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;
import com.tutict.finalassignmentbackend.service.offense.OffenseRecordService;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AgentRuntimeStreamTest {

    @Test
    void mockProviderEmitsToolCallThenResultThenFinalToken() {
        OffenseRecordService service = mock(OffenseRecordService.class);
        OffenseRecord record = new OffenseRecord();
        record.setOffenseId(11L);
        record.setDriverId(100L);
        record.setOffenseNumber("OWN-1");
        when(service.findByDriverId(eq(100L), anyInt(), anyInt())).thenReturn(List.of(record));

        QueryOffensesTool query = new QueryOffensesTool(service);
        AgentToolRegistry registry = new AgentToolRegistry(List.of(query));
        AgentToolContextFactory factory = mock(AgentToolContextFactory.class);
        when(factory.create(anyString(), anyMap())).thenReturn(
                new AgentToolContext(null, AiAgentRole.DRIVER, "s1", "testuser", 10L, 100L, false, null)
        );

        AiProviderProperties properties = new AiProviderProperties();
        properties.getProvider().setPrimary("scripted");
        properties.getProvider().setFallback("noop");
        properties.getProvider().setRetryAttempts(0);
        AiProviderRegistry providers = new AiProviderRegistry(
                List.of(new ScriptedToolProvider(), new NoopAiProvider()),
                properties
        );
        AgentIntentRouter silentRouter = new AgentIntentRouter() {
            @Override
            public List<AgentToolCall> route(String message, AiAgentRole role) {
                return List.of();
            }
        };
        AgentRuntime runtime = new AgentRuntime(
                providers,
                registry,
                factory,
                new InMemoryAgentDraftStore(),
                silentRouter,
                new ObjectMapper(),
                4
        );

        List<ChatStreamEvent> events = runtime.run("查一下我的违法", "s1", "assembled prompt", Map.of())
                .collectList()
                .block(Duration.ofSeconds(3));

        assertThat(events).extracting(ChatStreamEvent::type).contains(
                "tool", "result", "action", "token", "done"
        );
        assertThat(events).anyMatch(event ->
                "result".equals(event.type()) && String.valueOf(event.payload()).contains("违法"));
        assertThat(events).anyMatch(event -> "token".equals(event.type()) && "这是您的违法摘要。".equals(event.token()));
        assertThat(events.getLast().type()).isEqualTo("done");
    }

    private static final class ScriptedToolProvider implements AiProvider {
        private final AtomicInteger round = new AtomicInteger();

        @Override
        public String providerName() {
            return "scripted";
        }

        @Override
        public boolean supportsStreaming() {
            return true;
        }

        @Override
        public Flux<AiToken> stream(AiChatPrompt prompt, AiGenerationOptions options) {
            if (round.getAndIncrement() == 0) {
                return Flux.just(new AiToken("", true, Map.of(
                        "toolCalls", List.of(Map.of("id", "c1", "name", "query_my_offenses", "arguments", Map.of()))
                )));
            }
            return Flux.just(
                    new AiToken("这是您的违法摘要。", false, Map.of()),
                    new AiToken("", true, Map.of())
            );
        }

        @Override
        public Mono<AiMessage> complete(AiChatPrompt prompt, AiGenerationOptions options) {
            return Mono.just(new AiMessage("ok", Map.of()));
        }

        @Override
        public Mono<ProviderHealth> health() {
            return Mono.just(ProviderHealth.up("scripted"));
        }
    }
}
