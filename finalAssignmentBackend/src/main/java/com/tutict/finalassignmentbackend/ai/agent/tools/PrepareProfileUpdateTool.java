package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.entity.driver.DriverInformation;
import com.tutict.finalassignmentbackend.service.driver.DriverInformationService;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

@Component
public class PrepareProfileUpdateTool implements AgentTool {
    private final DriverInformationService driverInformationService;
    public PrepareProfileUpdateTool(DriverInformationService driverInformationService) { this.driverInformationService = driverInformationService; }
    @Override public String name() { return "prepare_profile_update"; }
    @Override public String description() { return "起草个人资料更新。确认后才会保存。"; }
    @Override public Map<String, Object> parameterSchema() {
        return Map.of("type", "object", "properties", Map.of(
                "contactNumber", Map.of("type", "string"),
                "address", Map.of("type", "string"),
                "driverLicenseNumber", Map.of("type", "string")
        ));
    }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.DRIVER); }
    @Override public boolean mutation() { return true; }
    @Override public String risk() { return "low"; }
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
        DriverInformation driver = driverInformationService.getDriverById(context.driverId());
        if (driver == null) return AgentToolResult.error("未找到驾驶员档案。");
        if (preview.get("contactNumber") != null) driver.setContactNumber((String) preview.get("contactNumber"));
        if (preview.get("address") != null) driver.setAddress((String) preview.get("address"));
        if (preview.get("driverLicenseNumber") != null) driver.setDriverLicenseNumber((String) preview.get("driverLicenseNumber"));
        driver.setUpdatedBy(context.username());
        DriverInformation saved = driverInformationService.updateDriver(driver);
        return AgentToolResult.result("个人资料已更新。", java.util.List.of(Map.of("id", saved.getDriverId(), "name", saved.getName())), AgentDrafts.navigate("打开个人资料", "/personalMain"));
    }
}
