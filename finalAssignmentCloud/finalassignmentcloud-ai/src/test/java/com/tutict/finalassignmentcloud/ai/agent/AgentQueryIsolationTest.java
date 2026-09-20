package com.tutict.finalassignmentcloud.ai.agent;

import com.tutict.finalassignmentcloud.ai.agent.tools.QueryOffensesAdminTool;
import com.tutict.finalassignmentcloud.ai.agent.tools.QueryOffensesTool;
import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRole;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AgentQueryIsolationTest {

    @Test
    void driverQueryUsesOwnDriverIdAndIgnoresRequestedForeignId() {
        AgentBusinessGateway gateway = mock(AgentBusinessGateway.class);
        when(gateway.offenses(100L)).thenReturn(List.of(Map.of("offenseId", 11L, "driverId", 100L, "offenseNumber", "OWN-1")));

        AgentToolResult result = new QueryOffensesTool(gateway).execute(
                driverContext(),
                Map.of("driverId", 999)
        );

        assertThat(result.ok()).isTrue();
        assertThat(result.items()).extracting(item -> item.get("offenseId")).containsExactly(11L);
        verify(gateway).offenses(100L);
    }

    @Test
    void adminUnknownDriverIdReturnsEmptySummary() {
        AgentBusinessGateway gateway = mock(AgentBusinessGateway.class);
        when(gateway.offenses(999L)).thenReturn(List.of());

        AgentToolResult result = new QueryOffensesAdminTool(gateway).execute(
                adminContext(),
                Map.of("driverId", 999)
        );

        assertThat(result.ok()).isTrue();
        assertThat(result.items()).isEmpty();
        assertThat(result.summary()).contains("没有查询到");
    }

    private static AgentToolContext driverContext() {
        return new AgentToolContext(null, AiAgentRole.DRIVER, "s1", "testuser", 10L, 100L, false, null);
    }

    private static AgentToolContext adminContext() {
        return new AgentToolContext(null, AiAgentRole.ADMIN, "s1", "admin", 1L, null, false, null);
    }
}
