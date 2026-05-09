package com.tutict.finalassignmentbackend.payment.governance;

import com.tutict.finalassignmentbackend.config.statemachine.states.PaymentState;
import com.tutict.finalassignmentbackend.entity.PaymentRecord;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class PaymentGovernanceShadowAuditTest {

    private final PaymentGovernanceClassifier classifier = new PaymentGovernanceClassifier();

    @Test
    void kafkaUpdateClassifiesAsFullUpdateShadowMutation() {
        PaymentGovernanceClassifier.Classification classification =
                classifier.classifyKafkaMutation("update", false);

        assertThat(classification.semanticEventType()).isEqualTo(PaymentSemanticEventType.FULL_UPDATE);
        assertThat(classification.sideEffects())
                .contains(PaymentSideEffect.DB_MUTATION, PaymentSideEffect.ES_INDEX, PaymentSideEffect.CACHE_EVICT)
                .doesNotContain(PaymentSideEffect.NONE);
    }

    @Test
    void duplicateClassifiesAsNoOpWithoutSideEffects() {
        PaymentGovernanceClassifier.Classification classification =
                classifier.classifyControllerMutation("create", true);

        assertThat(classification.semanticEventType()).isEqualTo(PaymentSemanticEventType.NO_OP);
        assertThat(classification.sideEffects()).containsOnly(PaymentSideEffect.NONE);
    }

    @Test
    void paidWorkflowClassifiesFinancialCompletionSideEffect() {
        PaymentGovernanceClassifier.Classification classification =
                classifier.classifyWorkflowStatus(PaymentState.PAID);

        assertThat(classification.semanticEventType()).isEqualTo(PaymentSemanticEventType.WORKFLOW);
        assertThat(classification.sideEffects())
                .contains(PaymentSideEffect.WORKFLOW_TRANSITION, PaymentSideEffect.PAYMENT_COMPLETION);
    }

    @Test
    void readRepairClassifiesQueryRepairWithoutMutationEnforcement() {
        PaymentGovernanceClassifier.Classification classification = classifier.classifyReadRepair();

        assertThat(classification.semanticEventType()).isEqualTo(PaymentSemanticEventType.READ_REPAIR);
        assertThat(classification.sideEffects())
                .contains(PaymentSideEffect.READ_REPAIR, PaymentSideEffect.ES_INDEX);
    }

    @Test
    void structuredShadowLogPayloadIsStableAndNonSensitive() {
        PaymentRecord record = new PaymentRecord();
        record.setPaymentId(12L);
        record.setFineId(99L);
        record.setPaymentStatus("Pending");
        record.setPayerIdCard("should-not-log");
        record.setBankAccount("should-not-log");

        String payload = PaymentGovernanceLogFactory.shadowClassification(
                PaymentGovernanceSource.KAFKA,
                classifier.classifyKafkaMutation("update", false),
                record,
                "update"
        );

        assertThat(payload).isEqualTo(
                "paymentGovernance=SHADOW_CLASSIFIED rolloutMode=SHADOW source=KAFKA semantic=FULL_UPDATE "
                        + "sideEffects=[CACHE_EVICT,DB_MUTATION,ES_INDEX] paymentId=12 fineId=99 "
                        + "paymentStatus=Pending action=update"
        );
        assertThat(payload).doesNotContain("should-not-log", "payerIdCard", "bankAccount");
    }
}
