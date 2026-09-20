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
public class QueryFinesTool implements AgentTool {
    private final AgentBusinessGateway gateway;
    public QueryFinesTool(AgentBusinessGateway gateway) { this.gateway = gateway; }
    @Override public String name() { return "query_my_fines"; }
    @Override public String description() { return "查询当前驾驶员自己的罚款记录。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema(); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.DRIVER); }
    @Override public boolean mutation() { return false; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        if (context.driverId() == null) return AgentToolResult.error("当前账号尚未绑定驾驶员档案，无法查询罚款。");
        try {
            var records = gateway.fines(context.driverId());
            return AgentToolResult.result(records.isEmpty() ? "没有查询到您的罚款记录。" : "共找到 " + records.size() + " 条罚款记录。",
                    AgentBusinessGateway.summarize(records, "fineId", "id", "fineNumber", "number", "fineAmount", "amount", "paymentStatus", "status", "licensePlate"),
                    AgentDrafts.navigate("查看罚款信息", "/fineInformation"));
        } catch (AgentBusinessException ex) {
            return AgentToolResult.error(ex.getMessage());
        }
    }
}
