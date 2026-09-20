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

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class QueryDriversTool implements AgentTool {
    private final DriverInformationService driverInformationService;
    public QueryDriversTool(DriverInformationService driverInformationService) { this.driverInformationService = driverInformationService; }
    @Override public String name() { return "query_drivers"; }
    @Override public String description() { return "管理员查询驾驶员档案。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema(); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return false; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        String query = AgentArgs.str(arguments, "query", "name");
        int page = AgentArgs.page(arguments);
        int size = AgentArgs.size(arguments, 10);
        List<DriverInformation> records = query == null || query.isBlank()
                ? driverInformationService.getAllDrivers()
                : driverInformationService.searchByName(query, page, size);
        if (records.size() > size) records = records.subList(0, size);
        List<Map<String, Object>> items = new ArrayList<>();
        for (DriverInformation record : records) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", record.getDriverId());
            item.put("name", record.getName());
            item.put("license", record.getDriverLicenseNumber());
            items.add(item);
        }
        return AgentToolResult.result(records.isEmpty() ? "没有查询到驾驶员。" : "共找到 " + records.size() + " 名驾驶员。", items, AgentDrafts.navigate("打开驾驶员管理", "/driverList"));
    }
}
