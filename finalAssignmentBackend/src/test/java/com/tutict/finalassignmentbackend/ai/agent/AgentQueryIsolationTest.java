package com.tutict.finalassignmentbackend.ai.agent;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryOffensesAdminTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryOffensesTool;
import com.tutict.finalassignmentbackend.ai.chat.ChatStreamEvent;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.ai.provider.AiProviderProperties;
import com.tutict.finalassignmentbackend.ai.provider.AiProviderRegistry;
import com.tutict.finalassignmentbackend.ai.provider.NoopAiProvider;
import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;
import com.tutict.finalassignmentbackend.service.offense.OffenseRecordService;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AgentQueryIsolationTest {

    @Test
    void driverQueryUsesOwnDriverIdAndIgnoresRequestedForeignId() {
        OffenseRecordService service = mock(OffenseRecordService.class);
        OffenseRecord own = new OffenseRecord();
        own.setOffenseId(11L);
        own.setDriverId(100L);
        own.setOffenseNumber("OWN-1");
        when(service.findByDriverId(eq(100L), anyInt(), anyInt())).thenReturn(List.of(own));

        AgentToolResult result = new QueryOffensesTool(service).execute(
                driverContext(),
                Map.of("driverId", 999)
        );

        assertThat(result.ok()).isTrue();
        assertThat(result.items()).extracting(item -> item.get("id")).containsExactly(11L);
        verify(service).findByDriverId(100L, 0, 10);
    }

    @Test
    void adminUnknownDriverIdReturnsEmptySummary() {
        OffenseRecordService service = mock(OffenseRecordService.class);
        when(service.findByDriverId(eq(999L), anyInt(), anyInt())).thenReturn(List.of());

        AgentToolResult result = new QueryOffensesAdminTool(service).execute(
                adminContext(),
                Map.of("driverId", 999)
        );

        assertThat(result.ok()).isTrue();
        assertThat(result.items()).isEmpty();
        assertThat(result.summary()).contains("没有查询到");
    }

    @Test
    void driverRuntimeRejectsAdminTool() {
        QueryOffensesAdminTool adminTool = new QueryOffensesAdminTool(mock(OffenseRecordService.class));
        AgentToolRegistry registry = new AgentToolRegistry(List.of(adminTool));
        AgentToolContextFactory factory = mock(AgentToolContextFactory.class);
        when(factory.create(anyString(), anyMap())).thenReturn(driverContext());
        AgentIntentRouter router = new AgentIntentRouter() {
            @Override
            public List<AgentToolCall> route(String message, AiAgentRole role) {
                return List.of(new AgentToolCall("x", "query_offenses", Map.of("driverId", 1)));
            }
        };
        AgentRuntime runtime = new AgentRuntime(
                new AiProviderRegistry(List.of(new NoopAiProvider()), new AiProviderProperties()),
                registry,
                factory,
                new InMemoryAgentDraftStore(),
                router,
                new ObjectMapper(),
                1
        );

        List<ChatStreamEvent> events = runtime.run("查别人的违法", "s1", "prompt", Map.of())
                .collectList()
                .block(Duration.ofSeconds(2));

        assertThat(events).anyMatch(event ->
                "result".equals(event.type())
                        && String.valueOf(event.payload()).contains("无权"));
    }

    private static AgentToolContext driverContext() {
        return new AgentToolContext(null, AiAgentRole.DRIVER, "s1", "testuser", 10L, 100L, false, null);
    }

    private static AgentToolContext adminContext() {
        return new AgentToolContext(null, AiAgentRole.ADMIN, "s1", "admin", 1L, null, false, null);
    }
}
