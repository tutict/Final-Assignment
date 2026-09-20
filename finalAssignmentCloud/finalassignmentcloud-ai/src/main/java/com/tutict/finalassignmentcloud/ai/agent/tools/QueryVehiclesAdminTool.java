package com.tutict.finalassignmentcloud.ai.agent.tools;

import com.tutict.finalassignmentcloud.ai.agent.AgentArgs;
import com.tutict.finalassignmentcloud.ai.agent.AgentBusinessException;
import com.tutict.finalassignmentcloud.ai.agent.AgentBusinessGateway;
import com.tutict.finalassignmentcloud.ai.agent.AgentDrafts;
import com.tutict.finalassignmentcloud.ai.agent.AgentTool;
import com.tutict.finalassignmentcloud.ai.agent.AgentToolContext;
import com.tutict.finalassignmentcloud.ai.agent.AgentToolResult;
import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRole;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Component
public class QueryVehiclesAdminTool implements AgentTool {
    private final AgentBusinessGateway gateway;
    public QueryVehiclesAdminTool(AgentBusinessGateway gateway) { this.gateway = gateway; }
    @Override public String name() { return "query_vehicles"; }
    @Override public String description() { return "管理员查询车辆。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema(); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return false; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        try {
            var records = gateway.vehicles(AgentArgs.lng(arguments, "driverId", "id"));
            return AgentToolResult.result(records.isEmpty() ? "没有查询到车辆。" : "共找到 " + records.size() + " 辆车。",
                    AgentBusinessGateway.summarize(records, "vehicleId", "id", "licensePlate", "vehicleType", "status"),
                    AgentDrafts.navigate("打开车辆管理", "/vehicleInformation"));
        } catch (AgentBusinessException ex) {
            return AgentToolResult.error(ex.getMessage());
        }
    }
}
