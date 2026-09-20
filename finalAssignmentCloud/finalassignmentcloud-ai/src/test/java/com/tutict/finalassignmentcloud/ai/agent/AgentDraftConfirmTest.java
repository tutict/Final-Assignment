package com.tutict.finalassignmentcloud.ai.agent;

import com.tutict.finalassignmentcloud.ai.agent.tools.ConfirmDraftTool;
import com.tutict.finalassignmentcloud.ai.agent.tools.PrepareAppealTool;
import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRole;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AgentDraftConfirmTest {

    @Test
    void writeToolWithoutConfirmOnlyCreatesDraft() {
        AgentBusinessGateway gateway = mock(AgentBusinessGateway.class);
        PrepareAppealTool tool = new PrepareAppealTool(gateway);
        InMemoryAgentDraftStore store = new InMemoryAgentDraftStore();

        AgentToolResult result = tool.execute(driver(), Map.of("offenseId", 8, "reason", "事实有误"));
        assertThat(result.kind()).isEqualTo(AgentToolResult.KIND_DRAFT);
        assertThat(result.draft()).isNotNull();
        store.save(result.draft());
        verify(gateway, never()).createAppeal(any());
        assertThat(store.find(result.draft().draftId())).isPresent();
    }

    @Test
    void confirmDraftExecutesExistingService() {
        AgentBusinessGateway gateway = mock(AgentBusinessGateway.class);
        when(gateway.createAppeal(any())).thenReturn(Map.of("appealId", 88L, "offenseId", 8L));

        PrepareAppealTool prepare = new PrepareAppealTool(gateway);
        InMemoryAgentDraftStore store = new InMemoryAgentDraftStore();
        AgentToolRegistry registry = new AgentToolRegistry(java.util.List.of(prepare));
        ConfirmDraftTool confirm = new ConfirmDraftTool(store, registry);
        registry.register(confirm);

        AgentToolContext context = driver();
        AgentToolResult draftResult = prepare.execute(context, Map.of("offenseId", 8, "reason", "事实有误"));
        store.save(draftResult.draft());

        AgentToolResult confirmed = confirm.execute(context, Map.of("draftId", draftResult.draft().draftId()));
        assertThat(confirmed.ok()).isTrue();
        assertThat(confirmed.kind()).isEqualTo(AgentToolResult.KIND_RESULT);
        assertThat(confirmed.summary()).contains("88");
        verify(gateway).createAppeal(any());
        assertThat(store.find(draftResult.draft().draftId())).isEmpty();
    }

    @Test
    void expiredOrForeignDraftIsRejected() {
        AgentBusinessGateway gateway = mock(AgentBusinessGateway.class);
        PrepareAppealTool prepare = new PrepareAppealTool(gateway);
        InMemoryAgentDraftStore store = new InMemoryAgentDraftStore();
        AgentToolRegistry registry = new AgentToolRegistry(java.util.List.of(prepare));
        ConfirmDraftTool confirm = new ConfirmDraftTool(store, registry);

        AgentDraft expired = new AgentDraft(
                "expired-id", "10", "s1", "prepare_appeal", "AppealRecordService.createAppeal",
                "high", "即将提交申诉", Map.of(), Map.of("offenseId", 8),
                Instant.now().minusSeconds(120), Instant.now().minusSeconds(60));
        store.save(expired);
        AgentToolResult expiredResult = confirm.execute(driver(), Map.of("draftId", "expired-id"));
        assertThat(expiredResult.ok()).isFalse();
        assertThat(expiredResult.summary()).contains("过期");
        verify(gateway, never()).createAppeal(any());

        AgentDraft foreign = new AgentDraft(
                "foreign-id", "other-user", "s1", "prepare_appeal", "AppealRecordService.createAppeal",
                "high", "即将提交申诉", Map.of(), Map.of("offenseId", 8),
                Instant.now(), Instant.now().plusSeconds(600));
        store.save(foreign);
        AgentToolResult foreignResult = confirm.execute(driver(), Map.of("draftId", "foreign-id"));
        assertThat(foreignResult.ok()).isFalse();
        assertThat(foreignResult.summary()).contains("其他用户");
        verify(gateway, never()).createAppeal(any());
    }

    @Test
    void foreignSessionKeyCannotSeeLastDraft() {
        InMemoryAgentDraftStore store = new InMemoryAgentDraftStore();
        assertThat(store.bindSession("10", "s1")).isTrue();
        store.rememberSessionDraft("10", "s1", "draft-a");
        assertThat(store.bindSession("other-user", "s1")).isFalse();
        assertThat(store.lastDraftId("other-user", "s1")).isEmpty();
        assertThat(store.lastDraftId("10", "s1")).contains("draft-a");
    }

    private static AgentToolContext driver() {
        return new AgentToolContext(null, AiAgentRole.DRIVER, "s1", "testuser", 10L, 100L, false, null);
    }
}
