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
public class PrepareOffenseCreateTool implements AgentTool {
    private final AgentBusinessGateway gateway;
    public PrepareOffenseCreateTool(AgentBusinessGateway gateway) { this.gateway = gateway; }
    @Override public String name() { return "prepare_offense_create"; }
    @Override public String description() { return "起草违法录入。确认后才会创建违法记录。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema("driverId"); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String serviceName() { return "OffenseRecordService.createOffenseRecord"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        Long driverId = AgentArgs.lng(arguments, "driverId", "id");
        String location = AgentArgs.str(arguments, "location", "offenseLocation", "query");
        String code = AgentArgs.str(arguments, "offenseCode", "code");
        Map<String, Object> preview = new LinkedHashMap<>();
        preview.put("driverId", driverId);
        preview.put("location", location);
        preview.put("offenseCode", code);
        if (!context.confirmed()) {
            return AgentToolResult.draft(AgentDrafts.create(context, this, "即将录入违法记录，请确认后办理。", preview, arguments));
        }
        try {
            Map<String, Object> body = new LinkedHashMap<>(arguments);
            body.put("driverId", driverId);
            body.put("offenseLocation", location);
            body.put("offenseCode", code);
            body.put("createdBy", context.username());
            Map<String, Object> saved = gateway.createOffense(body);
            return AgentToolResult.result("违法记录已录入，ID " + saved.getOrDefault("offenseId", saved.get("id")) + "。",
                    List.of(saved), AgentDrafts.navigate("打开违法管理", "/offenseList"));
        } catch (AgentBusinessException ex) {
            return AgentToolResult.error(ex.getMessage());
        }
    }
}
