package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDraft;
import com.tutict.finalassignmentbackend.ai.agent.AgentDraftStore;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolRegistry;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Set;

@Component
public class ConfirmDraftTool implements AgentTool {

    private final AgentDraftStore draftStore;
    private final AgentToolRegistry registry;

    public ConfirmDraftTool(AgentDraftStore draftStore, @Lazy AgentToolRegistry registry) {
        this.draftStore = draftStore;
        this.registry = registry;
    }

    @Override
    public String name() {
        return "confirm_draft";
    }

    @Override
    public String description() {
        return "确认并执行待办理草稿。用户说确认办理时调用。";
    }

    @Override
    public Map<String, Object> parameterSchema() {
        return Map.of(
                "type", "object",
                "properties", Map.of("draftId", Map.of("type", "string")),
                "required", java.util.List.of("draftId")
        );
    }

    @Override
    public Set<AiAgentRole> roles() {
        return Set.of(AiAgentRole.DRIVER, AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN);
    }

    @Override
    public boolean mutation() {
        return true;
    }

    @Override
    public String risk() {
        return "high";
    }

    @Override
    public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        String draftId = AgentArgs.str(arguments, "draftId");
        if (draftId == null || draftId.isBlank()) {
            draftId = draftStore.lastDraftId(context.sessionKey()).orElse(null);
        }
        AgentDraft draft = draftStore.find(draftId).orElse(null);
        if (draft == null) {
            return AgentToolResult.error("没有待确认的办理草稿，或草稿已过期。");
        }
        if (!context.userKey().equals(draft.userId())) {
            return AgentToolResult.error("不能确认其他用户的办理草稿。");
        }
        AgentTool tool = registry.find(draft.toolName()).orElse(null);
        if (tool == null) {
            return AgentToolResult.error("草稿对应的工具已失效。");
        }
        if (!tool.roles().contains(context.role())) {
            return AgentToolResult.error("当前角色无权确认该办理草稿。");
        }
        AgentToolContext confirmed = new AgentToolContext(
                context.authentication(),
                context.role(),
                context.sessionKey(),
                context.username(),
                context.authUserId(),
                context.driverId(),
                true,
                draft.draftId()
        );
        AgentToolResult result = tool.execute(confirmed, draft.payload());
        if (result.ok()) {
            draftStore.delete(draft.draftId());
        }
        return result;
    }
}
