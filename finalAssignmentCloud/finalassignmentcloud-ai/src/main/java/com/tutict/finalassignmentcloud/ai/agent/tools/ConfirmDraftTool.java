package com.tutict.finalassignmentcloud.ai.agent.tools;

import com.tutict.finalassignmentcloud.ai.agent.AgentArgs;
import com.tutict.finalassignmentcloud.ai.agent.AgentBusinessException;
import com.tutict.finalassignmentcloud.ai.agent.AgentBusinessGateway;
import com.tutict.finalassignmentcloud.ai.agent.AgentDraft;
import com.tutict.finalassignmentcloud.ai.agent.AgentDraftStore;
import com.tutict.finalassignmentcloud.ai.agent.AgentDrafts;
import com.tutict.finalassignmentcloud.ai.agent.AgentTool;
import com.tutict.finalassignmentcloud.ai.agent.AgentToolContext;
import com.tutict.finalassignmentcloud.ai.agent.AgentToolRegistry;
import com.tutict.finalassignmentcloud.ai.agent.AgentToolResult;
import com.tutict.finalassignmentcloud.ai.client.rag.RagRetrievalResult;
import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRole;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Component
public class ConfirmDraftTool implements AgentTool {
    private final AgentDraftStore draftStore;
    private final AgentToolRegistry registry;
    public ConfirmDraftTool(AgentDraftStore draftStore, @Lazy AgentToolRegistry registry) {
        this.draftStore = draftStore;
        this.registry = registry;
    }
    @Override public String name() { return "confirm_draft"; }
    @Override public String description() { return "确认并执行待办理草稿。用户说确认办理时调用。"; }
    @Override public Map<String, Object> parameterSchema() {
        return Map.of("type", "object", "properties", Map.of("draftId", Map.of("type", "string")), "required", List.of("draftId"));
    }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.DRIVER, AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String risk() { return "high"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        String draftId = AgentArgs.str(arguments, "draftId");
        if (draftId == null || draftId.isBlank()) {
            draftId = draftStore.lastDraftId(context.userKey(), context.sessionKey()).orElse(null);
        }
        AgentDraft draft = draftStore.find(draftId).orElse(null);
        if (draft == null) return AgentToolResult.error("没有待确认的办理草稿，或草稿已过期。");
        if (!context.userKey().equals(draft.userId())) return AgentToolResult.error("不能确认其他用户的办理草稿。");
        AgentTool tool = registry.find(draft.toolName()).orElse(null);
        if (tool == null) return AgentToolResult.error("草稿对应的工具已失效。");
        if (!tool.roles().contains(context.role())) return AgentToolResult.error("当前角色无权确认该办理草稿。");
        AgentToolContext confirmed = new AgentToolContext(
                context.authentication(), context.role(), context.sessionKey(), context.username(),
                context.authUserId(), context.driverId(), true, draft.draftId());
        AgentToolResult result = tool.execute(confirmed, draft.payload());
        if (result.ok()) draftStore.delete(draft.draftId());
        return result;
    }
}
