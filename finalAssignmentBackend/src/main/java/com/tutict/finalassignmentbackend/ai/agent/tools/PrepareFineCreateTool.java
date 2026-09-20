package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.entity.offense.FineRecord;
import com.tutict.finalassignmentbackend.service.offense.FineRecordService;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

@Component
public class PrepareFineCreateTool implements AgentTool {
    private final FineRecordService fineRecordService;
    public PrepareFineCreateTool(FineRecordService fineRecordService) { this.fineRecordService = fineRecordService; }
    @Override public String name() { return "prepare_fine_create"; }
    @Override public String description() { return "起草罚款录入。确认后才会创建罚款。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema("driverId"); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.ADMIN, AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return true; }
    @Override public String serviceName() { return "FineRecordService.createFineRecord"; }
    @Override public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        Long driverId = AgentArgs.lng(arguments, "driverId", "id");
        Long offenseId = AgentArgs.lng(arguments, "offenseId");
        String amountText = AgentArgs.str(arguments, "amount", "fineAmount", "query");
        Map<String, Object> preview = new LinkedHashMap<>();
        preview.put("driverId", driverId);
        preview.put("offenseId", offenseId);
        preview.put("amount", amountText);
        if (!context.confirmed()) {
            return AgentToolResult.draft(AgentDrafts.create(context, this, "即将录入罚款，请确认后办理。", preview, arguments));
        }
        FineRecord record = new FineRecord();
        record.setDriverId(driverId);
        record.setOffenseId(offenseId);
        if (amountText != null) {
            try { record.setFineAmount(new BigDecimal(amountText)); } catch (NumberFormatException ignored) {}
        }
        record.setFineDate(LocalDate.now());
        record.setPaymentStatus("UNPAID");
        record.setCreatedBy(context.username());
        FineRecord saved = fineRecordService.createFineRecord(record);
        return AgentToolResult.result("罚款已录入，ID " + saved.getFineId() + "。", QueryFinesTool.summarize(java.util.List.of(saved)), AgentDrafts.navigate("打开罚款管理", "/fineList"));
    }
}
