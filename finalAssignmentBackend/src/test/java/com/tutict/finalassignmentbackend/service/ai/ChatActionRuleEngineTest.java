package com.tutict.finalassignmentbackend.service.ai;

import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.model.ai.ChatActionResponse;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ChatActionRuleEngineTest {

    private final ChatActionRuleEngine engine = new ChatActionRuleEngine();

    @Test
    void resolvesDriverFinePaymentActionAndPrefillsPlate() {
        ChatActionResponse response = engine.resolve(
                "帮我处理罚款缴纳，车牌是粤B12345",
                AiAgentRole.DRIVER
        ).orElseThrow();

        assertThat(response.getAnswer()).contains("罚款缴纳");
        assertThat(response.getActions()).hasSize(1);
        assertThat(response.getActions().getFirst().getTarget()).isEqualTo("/fineInformation");
        assertThat(response.getActions().getFirst().getValue()).contains("\"licensePlate\":\"粤B12345\"");
        assertThat(response.isNeedConfirm()).isFalse();
    }

    @Test
    void resolvesAdminAppealApprovalAction() {
        ChatActionResponse response = engine.resolve(
                "请打开申诉审批管理页面",
                AiAgentRole.ADMIN
        ).orElseThrow();

        assertThat(response.getActions()).hasSize(1);
        assertThat(response.getActions().getFirst().getTarget()).isEqualTo("/appealManagement");
    }

    @Test
    void resolvesSuperAdminRagAction() {
        ChatActionResponse response = engine.resolve(
                "我要进入RAG资料管理并录入文档",
                AiAgentRole.SUPER_ADMIN
        ).orElseThrow();

        assertThat(response.getActions()).hasSize(1);
        assertThat(response.getActions().getFirst().getTarget()).isEqualTo("/admin/ragManagement");
    }

    @Test
    void doesNotEscalateRagIntentForAdminRole() {
        assertThat(engine.resolve("打开RAG资料管理", AiAgentRole.ADMIN)).isEmpty();
    }
}
