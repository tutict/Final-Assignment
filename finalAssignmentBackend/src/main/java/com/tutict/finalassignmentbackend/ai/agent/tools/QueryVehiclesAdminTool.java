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

import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class QueryVehiclesAdminTool implements AgentTool {
    private final VehicleInformationService vehicleInformationService;
    public QueryVehiclesAdminTool(VehicleInformationService vehicleInformationService) { this.vehicleInformationService = vehicleInformationService; }
    @Override public String name() { return "query_vehicles"; }
    @Override public String description() { return "管理员查询车辆档案。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema(); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return false; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        String query = AgentArgs.str(arguments, "query", "licensePlate");
        Long driverId = AgentArgs.lng(arguments, "driverId", "id");
        List<VehicleInformation> records;
        if (driverId != null) records = vehicleInformationService.getVehicleInformationByDriverId(driverId, AgentArgs.page(arguments), AgentArgs.size(arguments, 10));
        else if (query != null && !query.isBlank()) records = vehicleInformationService.searchVehicles(query, AgentArgs.page(arguments), AgentArgs.size(arguments, 10));
        else records = vehicleInformationService.getAllVehicleInformation();
        int size = AgentArgs.size(arguments, 10);
        if (records.size() > size) records = records.subList(0, size);
        return AgentToolResult.result(records.isEmpty() ? "没有查询到车辆。" : "共找到 " + records.size() + " 条车辆记录。", QueryVehiclesTool.summarize(records), AgentDrafts.navigate("打开车辆管理", "/vehicleList"));
    }
}
