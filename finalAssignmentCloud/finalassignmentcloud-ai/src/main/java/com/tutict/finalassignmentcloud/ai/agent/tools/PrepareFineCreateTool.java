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
public class PrepareFineCreateTool implements AgentTool {
    private final AgentBusinessGateway gateway;
    public PrepareFineCreateTool(AgentBusinessGateway gateway) { this.gateway = gateway; }
    @Override public String name() { return "prepare_fine_create"; }
    @Override public String description() { return "起草罚款录入。确认后才会创建罚款。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema("offenseId"); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String serviceName() { return "FineRecordService.createFineRecord"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        Map<String, Object> preview = new LinkedHashMap<>(arguments == null ? Map.of() : arguments);
        if (!context.confirmed()) {
            return AgentToolResult.draft(AgentDrafts.create(context, this, "即将录入罚款，请确认后办理。", preview, arguments));
        }
        try {
            Map<String, Object> saved = gateway.createFine(arguments == null ? Map.of() : arguments);
            return AgentToolResult.result("罚款已录入，ID " + saved.getOrDefault("fineId", saved.get("id")) + "。",
                    List.of(saved), AgentDrafts.navigate("打开罚款管理", "/fineInformation"));
        } catch (AgentBusinessException ex) {
            return AgentToolResult.error(ex.getMessage());
        }
    }
}
