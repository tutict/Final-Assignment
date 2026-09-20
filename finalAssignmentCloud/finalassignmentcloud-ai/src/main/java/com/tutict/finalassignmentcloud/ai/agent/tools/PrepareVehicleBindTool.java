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
public class PrepareVehicleBindTool implements AgentTool {
    private final AgentBusinessGateway gateway;
    public PrepareVehicleBindTool(AgentBusinessGateway gateway) { this.gateway = gateway; }
    @Override public String name() { return "prepare_vehicle_bind"; }
    @Override public String description() { return "起草车辆绑定。确认后才会绑定。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema("vehicleId"); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.DRIVER, AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String serviceName() { return "VehicleInformationService.bindDriver"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        Long vehicleId = AgentArgs.lng(arguments, "vehicleId", "id");
        if (vehicleId == null) return AgentToolResult.error("请提供车辆 ID。");
        Map<String, Object> preview = new LinkedHashMap<>(arguments == null ? Map.of() : arguments);
        preview.put("driverId", context.driverId());
        if (!context.confirmed()) {
            return AgentToolResult.draft(AgentDrafts.create(context, this, "即将绑定车辆，请确认后办理。", preview, arguments));
        }
        try {
            Map<String, Object> body = new LinkedHashMap<>(arguments == null ? Map.of() : arguments);
            if (context.driverId() != null) body.put("driverId", context.driverId());
            Map<String, Object> saved = gateway.bindVehicle(vehicleId, body);
            return AgentToolResult.result("车辆已绑定。", List.of(saved), AgentDrafts.navigate("查看我的车辆", "/vehicleInformation"));
        } catch (AgentBusinessException ex) {
            return AgentToolResult.error(ex.getMessage());
        }
    }
}
