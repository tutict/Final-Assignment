package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.entity.driver.VehicleInformation;
import com.tutict.finalassignmentbackend.service.driver.VehicleInformationService;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

@Component
public class PrepareVehicleBindTool implements AgentTool {
    private final VehicleInformationService vehicleInformationService;
    public PrepareVehicleBindTool(VehicleInformationService vehicleInformationService) { this.vehicleInformationService = vehicleInformationService; }
    @Override public String name() { return "prepare_vehicle_bind"; }
    @Override public String description() { return "起草绑定车辆。确认后才会写入车辆档案。"; }
    @Override public Map<String, Object> parameterSchema() {
        return Map.of("type", "object", "properties", Map.of(
                "licensePlate", Map.of("type", "string"),
                "vehicleType", Map.of("type", "string"),
                "ownerName", Map.of("type", "string")
        ), "required", java.util.List.of("licensePlate"));
    }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.DRIVER, AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String serviceName() { return "VehicleInformationService.createVehicleInformation"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        String plate = AgentArgs.str(arguments, "licensePlate", "plate", "query");
        if (plate == null || plate.isBlank()) return AgentToolResult.error("请提供车牌号。");
        if (context.isUser() && context.driverId() == null) return AgentToolResult.error("请先完善驾驶员档案再绑定车辆。");
        Map<String, Object> preview = new LinkedHashMap<>();
        preview.put("licensePlate", plate.toUpperCase());
        preview.put("vehicleType", AgentArgs.str(arguments, "vehicleType"));
        preview.put("driverId", context.driverId());
        if (!context.confirmed()) {
            return AgentToolResult.draft(AgentDrafts.create(context, this, "即将绑定车辆 " + plate + "，请确认后办理。", preview, arguments));
        }
        VehicleInformation vehicle = new VehicleInformation();
        vehicle.setLicensePlate(plate.toUpperCase());
        vehicle.setDriverId(context.driverId());
        vehicle.setVehicleType(AgentArgs.str(arguments, "vehicleType"));
        vehicle.setOwnerName(AgentArgs.str(arguments, "ownerName"));
        vehicle.setCreatedBy(context.username());
        vehicle.setUpdatedBy(context.username());
        VehicleInformation saved = vehicleInformationService.createVehicleInformation(vehicle);
        return AgentToolResult.result("车辆已绑定，车牌 " + saved.getLicensePlate() + "。", QueryVehiclesTool.summarize(java.util.List.of(saved)), AgentDrafts.navigate("打开车辆管理", "/vehicleManagement"));
    }
}
