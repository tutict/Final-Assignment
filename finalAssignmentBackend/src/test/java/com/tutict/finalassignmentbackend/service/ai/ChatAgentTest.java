package com.tutict.finalassignmentbackend.service.ai;

import com.tutict.finalassignmentbackend.ai.prompt.AgentConstraintService;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRoleResolver;
import com.tutict.finalassignmentbackend.ai.provider.AiMessage;
import com.tutict.finalassignmentbackend.ai.provider.AiProviderRegistry;
import com.tutict.finalassignmentbackend.model.ai.ChatActionResponse;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Mono;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class ChatAgentTest {

    @Test
    void chatWithActionsUsesProviderRegistryResponse() {
        AiProviderRegistry registry = mock(AiProviderRegistry.class);
        when(registry.complete(anyString(), anyMap())).thenReturn(Mono.just(new AiMessage("""
                {
                  "answer": "ok",
                  "actions": [
                    {"type": "NAVIGATE", "label": "Open appeals", "target": "/appeals", "value": ""}
                  ],
                  "needConfirm": true
                }
                """, Map.of("provider", "ollama"))));

        ChatActionResponse response = agent(registry).chatWithActions("open appeal page", null, false);

        assertThat(response.getAnswer()).isEqualTo("ok");
        assertThat(response.getActions()).hasSize(1);
        assertThat(response.getActions().getFirst().getType()).isEqualTo("NAVIGATE");
        assertThat(response.getActions().getFirst().getTarget()).isEqualTo("/appeals");
        assertThat(response.isNeedConfirm()).isTrue();
    }

    @Test
    void chatWithActionsUsesLocalRuleBeforeProvider() {
        AiProviderRegistry registry = mock(AiProviderRegistry.class);

        ChatActionResponse response = agent(registry).chatWithActions("帮我查看违法处理入口", null, false);

        assertThat(response.getActions()).hasSize(1);
        assertThat(response.getActions().getFirst().getTarget()).isEqualTo("/userOffenseListPage");
        verifyNoInteractions(registry);
    }

    @Test
    void chatWithActionsReturnsEmptyActionsWhenProviderFails() {
        AiProviderRegistry registry = mock(AiProviderRegistry.class);
        when(registry.complete(anyString(), anyMap())).thenReturn(Mono.error(new RuntimeException("boom")));

        ChatActionResponse response = agent(registry).chatWithActions("open appeal page", null, false);

        assertThat(response.getAnswer()).contains("暂时不可用");
        assertThat(response.getActions()).isEmpty();
        assertThat(response.isNeedConfirm()).isFalse();
    }

    @Test
    void chatWithActionsLocalizesNoopFallbackResponse() {
        AiProviderRegistry registry = mock(AiProviderRegistry.class);
        when(registry.complete(anyString(), anyMap())).thenReturn(Mono.just(new AiMessage(
                "AI provider unavailable.",
                Map.of("provider", "noop", "fallback", true)
        )));

        ChatActionResponse response = agent(registry).chatWithActions("open appeal page", null, false);

        assertThat(response.getAnswer()).contains("暂时不可用");
        assertThat(response.getActions()).isEmpty();
        assertThat(response.isNeedConfirm()).isFalse();
    }

    private static ChatAgent agent(AiProviderRegistry registry) {
        AiAgentRoleResolver roleResolver = mock(AiAgentRoleResolver.class);
        AgentConstraintService constraintService = mock(AgentConstraintService.class);
        AIChatSearchService searchService = mock(AIChatSearchService.class);
        when(roleResolver.resolve(anyMap())).thenReturn(AiAgentRole.DRIVER);
        when(constraintService.constraintsFor(AiAgentRole.DRIVER)).thenReturn("# test policy");
        return new ChatAgent(null, registry, searchService, roleResolver, constraintService, new ChatActionRuleEngine());
    }
}
