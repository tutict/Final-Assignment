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
public class PrepareFinePaymentTool implements AgentTool {
    private final AgentBusinessGateway gateway;
    public PrepareFinePaymentTool(AgentBusinessGateway gateway) { this.gateway = gateway; }
    @Override public String name() { return "prepare_fine_payment"; }
    @Override public String description() { return "起草罚款缴纳。确认后才会创建缴款记录。"; }
    @Override public Map<String, Object> parameterSchema() {
        return Map.of("type", "object", "properties", Map.of("fineId", Map.of("type", "integer")), "required", List.of("fineId"));
    }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.DRIVER, AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String risk() { return "high"; }
    @Override public String serviceName() { return "PaymentRecordService.createPaymentRecord"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        Long fineId = AgentArgs.lng(arguments, "fineId", "id");
        if (fineId == null) return AgentToolResult.error("请提供罚款 ID。");
        try {
            Map<String, Object> fine = gateway.fine(fineId);
            if (fine == null || fine.isEmpty()) return AgentToolResult.error("未找到罚款记录。");
            Long owner = AgentBusinessGateway.longValue(fine, "driverId");
            if (context.isUser() && context.driverId() != null && owner != null && !context.driverId().equals(owner)) {
                return AgentToolResult.error("不能缴纳其他驾驶员的罚款。");
            }
            Map<String, Object> preview = new LinkedHashMap<>();
            preview.put("fineId", fineId);
            preview.put("amount", fine.get("fineAmount"));
            preview.put("status", fine.get("paymentStatus"));
            if (!context.confirmed()) {
                return AgentToolResult.draft(AgentDrafts.create(context, this, "即将缴纳罚款 " + fine.get("fineAmount") + "，请确认后办理。", preview, arguments));
            }
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("fineId", fineId);
            body.put("driverId", owner);
            body.put("paymentAmount", fine.getOrDefault("unpaidAmount", fine.get("fineAmount")));
            body.put("createdBy", context.username());
            Map<String, Object> saved = gateway.createPayment(body);
            return AgentToolResult.result("罚款缴纳已登记，支付记录 " + saved.getOrDefault("paymentId", saved.get("id")) + "。",
                    List.of(saved), AgentDrafts.navigate("查看罚款信息", "/fineInformation"));
        } catch (AgentBusinessException ex) {
            return AgentToolResult.error(ex.getMessage());
        }
    }
}
