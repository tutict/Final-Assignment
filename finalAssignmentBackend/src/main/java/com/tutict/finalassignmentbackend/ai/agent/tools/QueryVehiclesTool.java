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

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class QueryVehiclesTool implements AgentTool {
    private final VehicleInformationService vehicleInformationService;

    public QueryVehiclesTool(VehicleInformationService vehicleInformationService) {
        this.vehicleInformationService = vehicleInformationService;
    }

    @Override
    public String name() {
        return "query_my_vehicles";
    }

    @Override
    public String description() {
        return "查询当前驾驶员绑定的车辆。";
    }

    @Override
    public Map<String, Object> parameterSchema() {
        return AgentDrafts.schema();
    }

    @Override
    public Set<AiAgentRole> roles() {
        return Set.of(AiAgentRole.DRIVER);
    }

    @Override
    public boolean mutation() {
        return false;
    }

    @Override
    public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        if (context.driverId() == null) {
            return AgentToolResult.error("当前账号尚未绑定驾驶员档案，无法查询车辆。");
        }
        List<VehicleInformation> records = vehicleInformationService.getVehicleInformationByDriverId(
                context.driverId(),
                AgentArgs.page(arguments),
                AgentArgs.size(arguments, 10)
        );
        return AgentToolResult.result(
                records.isEmpty() ? "没有查询到您的车辆。" : "共找到 " + records.size() + " 辆绑定车辆。",
                summarize(records),
                AgentDrafts.navigate("打开车辆管理", "/vehicleManagement")
        );
    }

    static List<Map<String, Object>> summarize(List<VehicleInformation> records) {
        List<Map<String, Object>> items = new ArrayList<>();
        for (VehicleInformation record : records) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", record.getVehicleId());
            item.put("plate", record.getLicensePlate());
            item.put("type", record.getVehicleType());
            item.put("status", record.getStatus());
            items.add(item);
        }
        return items;
    }
}
