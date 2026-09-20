package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.entity.offense.FineRecord;
import com.tutict.finalassignmentbackend.entity.payment.PaymentRecord;
import com.tutict.finalassignmentbackend.service.offense.FineRecordService;
import com.tutict.finalassignmentbackend.service.payment.PaymentRecordService;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Component
public class PrepareFinePaymentTool implements AgentTool {
    private final FineRecordService fineRecordService;
    private final PaymentRecordService paymentRecordService;
    public PrepareFinePaymentTool(FineRecordService fineRecordService, PaymentRecordService paymentRecordService) {
        this.fineRecordService = fineRecordService;
        this.paymentRecordService = paymentRecordService;
    }
    @Override public String name() { return "prepare_fine_payment"; }
    @Override public String description() { return "起草罚款缴纳。确认后才会创建缴款记录。"; }
    @Override public Map<String, Object> parameterSchema() {
        return Map.of("type", "object", "properties", Map.of("fineId", Map.of("type", "integer")), "required", java.util.List.of("fineId"));
    }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.DRIVER, AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String risk() { return "high"; }
    @Override public String serviceName() { return "PaymentRecordService.createPaymentRecord"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        Long fineId = AgentArgs.lng(arguments, "fineId", "id");
        if (fineId == null) return AgentToolResult.error("请提供罚款 ID。");
        FineRecord fine = fineRecordService.findById(fineId);
        if (fine == null) return AgentToolResult.error("未找到罚款记录。");
        if (context.isUser() && context.driverId() != null && !context.driverId().equals(fine.getDriverId())) {
            return AgentToolResult.error("不能缴纳其他驾驶员的罚款。");
        }
        Map<String, Object> preview = new LinkedHashMap<>();
        preview.put("fineId", fineId);
        preview.put("amount", fine.getFineAmount());
        preview.put("status", fine.getPaymentStatus());
        if (!context.confirmed()) {
            return AgentToolResult.draft(AgentDrafts.create(context, this, "即将缴纳罚款 " + fine.getFineAmount() + "，请确认后办理。", preview, arguments));
        }
        PaymentRecord payment = new PaymentRecord();
        payment.setFineId(fineId);
        payment.setDriverId(fine.getDriverId());
        payment.setPaymentAmount(fine.getUnpaidAmount() != null ? fine.getUnpaidAmount() : fine.getFineAmount());
        payment.setCreatedBy(context.username());
        PaymentRecord saved = paymentRecordService.createPaymentRecord(payment, UUID.randomUUID().toString());
        return AgentToolResult.result("罚款缴纳已登记，支付记录 " + saved.getPaymentId() + "。", java.util.List.of(Map.of("paymentId", saved.getPaymentId(), "fineId", fineId)), AgentDrafts.navigate("查看罚款信息", "/fineInformation"));
    }
}
