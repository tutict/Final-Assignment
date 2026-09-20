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
public class PrepareProfileUpdateTool implements AgentTool {
    private final AgentBusinessGateway gateway;
    public PrepareProfileUpdateTool(AgentBusinessGateway gateway) { this.gateway = gateway; }
    @Override public String name() { return "prepare_profile_update"; }
    @Override public String description() { return "起草个人资料更新。确认后才会保存。"; }
    @Override public Map<String, Object> parameterSchema() {
        return Map.of("type", "object", "properties", Map.of(
                "contactNumber", Map.of("type", "string"),
                "address", Map.of("type", "string"),
                "driverLicenseNumber", Map.of("type", "string")));
    }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.DRIVER); }
    @Override public boolean mutation() { return true; }
    @Override public String serviceName() { return "DriverInformationService.updateDriver"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        if (context.driverId() == null) return AgentToolResult.error("当前账号没有驾驶员档案。");
        Map<String, Object> preview = new LinkedHashMap<>();
        preview.put("driverId", context.driverId());
        preview.put("contactNumber", AgentArgs.str(arguments, "contactNumber", "phone"));
        preview.put("address", AgentArgs.str(arguments, "address"));
        preview.put("driverLicenseNumber", AgentArgs.str(arguments, "driverLicenseNumber"));
        if (!context.confirmed()) {
            return AgentToolResult.draft(AgentDrafts.create(context, this, "即将更新个人资料，请确认后办理。", preview, arguments));
        }
        try {
            Map<String, Object> driver = new LinkedHashMap<>(gateway.driver(context.driverId()));
            if (preview.get("contactNumber") != null) driver.put("contactNumber", preview.get("contactNumber"));
            if (preview.get("address") != null) driver.put("address", preview.get("address"));
            if (preview.get("driverLicenseNumber") != null) driver.put("driverLicenseNumber", preview.get("driverLicenseNumber"));
            driver.put("updatedBy", context.username());
            Map<String, Object> saved = gateway.updateDriver(context.driverId(), driver);
            return AgentToolResult.result("个人资料已更新。", List.of(saved), AgentDrafts.navigate("打开个人资料", "/personalMain"));
        } catch (AgentBusinessException ex) {
            return AgentToolResult.error(ex.getMessage());
        }
    }
}
