package com.tutict.finalassignmentbackend.ai.agent;

import com.tutict.finalassignmentbackend.ai.agent.tools.ConfirmDraftTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.IngestRagDocumentTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.NavigateBackupTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.PrepareAppealReviewTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.PrepareAppealTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.PrepareDeductionCreateTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.PrepareFineCreateTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.PrepareFinePaymentTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.PrepareOffenseCreateTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.PrepareProfileUpdateTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.PrepareVehicleBindTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryAppealsAdminTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryAppealsTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryDriversTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryFinesAdminTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryFinesTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryLogsTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryOffensesAdminTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryOffensesTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryProgressTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryRagStatusTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryUsersTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryVehiclesAdminTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.QueryVehiclesTool;
import com.tutict.finalassignmentbackend.ai.agent.tools.SearchKnowledgeTool;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

class AgentToolRegistryTest {

    private AgentToolRegistry registry;

    @BeforeEach
    void setUp() {
        ConfirmDraftTool confirm = new ConfirmDraftTool(new InMemoryAgentDraftStore(), mock(AgentToolRegistry.class));
        registry = new AgentToolRegistry(List.of(
                new QueryOffensesTool(mock(com.tutict.finalassignmentbackend.service.offense.OffenseRecordService.class)),
                new QueryOffensesAdminTool(mock(com.tutict.finalassignmentbackend.service.offense.OffenseRecordService.class)),
                new QueryFinesTool(mock(com.tutict.finalassignmentbackend.service.offense.FineRecordService.class)),
                new QueryFinesAdminTool(mock(com.tutict.finalassignmentbackend.service.offense.FineRecordService.class)),
                new QueryAppealsTool(mock(com.tutict.finalassignmentbackend.service.appeal.AppealRecordService.class)),
                new QueryAppealsAdminTool(mock(com.tutict.finalassignmentbackend.service.appeal.AppealRecordService.class)),
                new QueryVehiclesTool(mock(com.tutict.finalassignmentbackend.service.driver.VehicleInformationService.class)),
                new QueryVehiclesAdminTool(mock(com.tutict.finalassignmentbackend.service.driver.VehicleInformationService.class)),
                new QueryDriversTool(mock(com.tutict.finalassignmentbackend.service.driver.DriverInformationService.class)),
                new QueryProgressTool(mock(com.tutict.finalassignmentbackend.service.system.SysRequestHistoryService.class)),
                new SearchKnowledgeTool(mock(ObjectProvider.class)),
                new PrepareAppealTool(mock(com.tutict.finalassignmentbackend.service.appeal.AppealRecordService.class)),
                new PrepareVehicleBindTool(mock(com.tutict.finalassignmentbackend.service.driver.VehicleInformationService.class)),
                new PrepareFinePaymentTool(
                        mock(com.tutict.finalassignmentbackend.service.offense.FineRecordService.class),
                        mock(com.tutict.finalassignmentbackend.service.payment.PaymentRecordService.class)
                ),
                new PrepareProfileUpdateTool(mock(com.tutict.finalassignmentbackend.service.driver.DriverInformationService.class)),
                new PrepareOffenseCreateTool(mock(com.tutict.finalassignmentbackend.service.offense.OffenseRecordService.class)),
                new PrepareFineCreateTool(mock(com.tutict.finalassignmentbackend.service.offense.FineRecordService.class)),
                new PrepareDeductionCreateTool(mock(com.tutict.finalassignmentbackend.service.offense.DeductionRecordService.class)),
                new PrepareAppealReviewTool(
                        mock(com.tutict.finalassignmentbackend.service.appeal.AppealReviewService.class),
                        mock(com.tutict.finalassignmentbackend.service.appeal.AppealRecordService.class)
                ),
                new QueryLogsTool(
                        mock(com.tutict.finalassignmentbackend.service.audit.AuditOperationLogService.class),
                        mock(com.tutict.finalassignmentbackend.service.audit.AuditLoginLogService.class)
                ),
                new QueryUsersTool(mock(com.tutict.finalassignmentbackend.service.admin.SysUserService.class)),
                new QueryRagStatusTool(mock(ObjectProvider.class), mock(ObjectProvider.class), mock(ObjectProvider.class)),
                new IngestRagDocumentTool(mock(ObjectProvider.class)),
                new NavigateBackupTool(),
                confirm
        ));
        registry.register(new ConfirmDraftTool(new InMemoryAgentDraftStore(), registry));
    }

    @Test
    void driverSeesSelfServiceToolsOnly() {
        assertThat(registry.namesFor(AiAgentRole.DRIVER)).containsExactlyInAnyOrder(
                "query_my_offenses",
                "query_my_fines",
                "query_my_appeals",
                "query_my_vehicles",
                "query_progress",
                "search_knowledge",
                "prepare_appeal",
                "prepare_vehicle_bind",
                "prepare_fine_payment",
                "prepare_profile_update",
                "confirm_draft"
        );
        assertThat(registry.namesFor(AiAgentRole.DRIVER))
                .doesNotContain("query_offenses", "query_logs", "prepare_offense_create");
    }

    @Test
    void adminSeesBusinessToolsButNotSuperAdminGovernance() {
        assertThat(registry.namesFor(AiAgentRole.ADMIN)).contains(
                "query_offenses",
                "query_fines",
                "query_appeals",
                "query_vehicles",
                "query_drivers",
                "prepare_offense_create",
                "prepare_appeal_review",
                "confirm_draft"
        );
        assertThat(registry.namesFor(AiAgentRole.ADMIN))
                .doesNotContain("query_my_offenses", "query_logs", "query_users");
        assertThat(registry.namesFor(AiAgentRole.ADMIN)).contains("ingest_rag_document", "query_rag_status");
    }

    @Test
    void superAdminSeesGovernanceTools() {
        assertThat(registry.namesFor(AiAgentRole.SUPER_ADMIN)).contains(
                "query_offenses",
                "query_logs",
                "query_users",
                "query_rag_status",
                "ingest_rag_document",
                "navigate_backup"
        );
    }
}
