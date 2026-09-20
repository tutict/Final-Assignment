package com.tutict.finalassignmentbackend.ai.agent;

import com.tutict.finalassignmentbackend.ai.agent.tools.ConfirmDraftTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.PrepareAppealTool;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import com.tutict.finalassignmentbackend.service.appeal.AppealRecordService;
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
        AppealRecordService service = mock(AppealRecordService.class);
        PrepareAppealTool tool = new PrepareAppealTool(service);
        InMemoryAgentDraftStore store = new InMemoryAgentDraftStore();
        AgentToolContext context = driver();

        AgentToolResult result = tool.execute(context, Map.of("offenseId", 8, "reason", "事实有误"));
        assertThat(result.kind()).isEqualTo(AgentToolResult.KIND_DRAFT);
        assertThat(result.draft()).isNotNull();
        store.save(result.draft());
        verify(service, never()).createAppeal(any());
        assertThat(store.find(result.draft().draftId())).isPresent();
    }

    @Test
    void confirmDraftExecutesExistingService() {
        AppealRecordService service = mock(AppealRecordService.class);
        AppealRecord saved = new AppealRecord();
        saved.setAppealId(88L);
        saved.setOffenseId(8L);
        when(service.createAppeal(any())).thenReturn(saved);

        PrepareAppealTool prepare = new PrepareAppealTool(service);
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
        verify(service).createAppeal(any());
        assertThat(store.find(draftResult.draft().draftId())).isEmpty();
    }

    @Test
    void expiredOrForeignDraftIsRejected() {
        AppealRecordService service = mock(AppealRecordService.class);
        PrepareAppealTool prepare = new PrepareAppealTool(service);
        InMemoryAgentDraftStore store = new InMemoryAgentDraftStore();
        AgentToolRegistry registry = new AgentToolRegistry(java.util.List.of(prepare));
        ConfirmDraftTool confirm = new ConfirmDraftTool(store, registry);

        AgentDraft expired = new AgentDraft(
                "expired-id",
                "10",
                "s1",
                "prepare_appeal",
                "AppealRecordService.createAppeal",
                "high",
                "即将提交申诉",
                Map.of(),
                Map.of("offenseId", 8),
                Instant.now().minusSeconds(120),
                Instant.now().minusSeconds(60)
        );
        store.save(expired);
        AgentToolResult expiredResult = confirm.execute(driver(), Map.of("draftId", "expired-id"));
        assertThat(expiredResult.ok()).isFalse();
        assertThat(expiredResult.summary()).contains("过期");
        verify(service, never()).createAppeal(any());

        AgentDraft foreign = new AgentDraft(
                "foreign-id",
                "other-user",
                "s1",
                "prepare_appeal",
                "AppealRecordService.createAppeal",
                "high",
                "即将提交申诉",
                Map.of(),
                Map.of("offenseId", 8),
                Instant.now(),
                Instant.now().plusSeconds(600)
        );
        store.save(foreign);
        AgentToolResult foreignResult = confirm.execute(driver(), Map.of("draftId", "foreign-id"));
        assertThat(foreignResult.ok()).isFalse();
        assertThat(foreignResult.summary()).contains("其他用户");
        verify(service, never()).createAppeal(any());
    }

    private static AgentToolContext driver() {
        return new AgentToolContext(null, AiAgentRole.DRIVER, "s1", "testuser", 10L, 100L, false, null);
    }
}
