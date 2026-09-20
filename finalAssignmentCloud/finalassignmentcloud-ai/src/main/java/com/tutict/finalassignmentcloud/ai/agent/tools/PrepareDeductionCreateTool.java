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
public class PrepareDeductionCreateTool implements AgentTool {
    private final AgentBusinessGateway gateway;
    public PrepareDeductionCreateTool(AgentBusinessGateway gateway) { this.gateway = gateway; }
    @Override public String name() { return "prepare_deduction_create"; }
    @Override public String description() { return "起草记分录入。确认后才会创建。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema("driverId"); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String serviceName() { return "DeductionRecordService.createDeduction"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        Map<String, Object> preview = new LinkedHashMap<>(arguments == null ? Map.of() : arguments);
        if (!context.confirmed()) {
            return AgentToolResult.draft(AgentDrafts.create(context, this, "即将录入记分，请确认后办理。", preview, arguments));
        }
        try {
            Map<String, Object> saved = gateway.createDeduction(arguments == null ? Map.of() : arguments);
            return AgentToolResult.result("记分已录入。", List.of(saved), AgentDrafts.navigate("打开记分管理", "/deductionInformation"));
        } catch (AgentBusinessException ex) {
            return AgentToolResult.error(ex.getMessage());
        }
    }
}
