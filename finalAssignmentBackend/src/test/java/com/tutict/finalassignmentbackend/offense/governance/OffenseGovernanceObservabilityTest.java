package com.tutict.finalassignmentbackend.offense.governance;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;
import com.tutict.finalassignmentbackend.mapper.offense.OffenseRecordMapper;
import com.tutict.finalassignmentbackend.mapper.system.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.OffenseInformationSearchRepository;
import com.tutict.finalassignmentbackend.service.offense.OffenseRecordService;
import org.junit.jupiter.api.Test;
import org.springframework.kafka.core.KafkaTemplate;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class OffenseGovernanceObservabilityTest {

    @Test
    void structuredDecisionCreationExposesRolloutHelpers() {
        OffenseGovernanceDecision decision = OffenseGovernanceLogFactory.shadowStale(
                OffenseGovernanceDecision.Source.CONTROLLER,
                10L,
                LocalDateTime.of(2026, 5, 8, 12, 0),
                LocalDateTime.of(2026, 5, 8, 11, 0)
        );

        assertThat(decision.type()).isEqualTo(OffenseGovernanceDecisionType.SHADOW_STALE);
        assertThat(decision.semanticEventType()).isEqualTo(SemanticEventType.FULL_UPDATE);
        assertThat(decision.source()).isEqualTo(OffenseGovernanceDecision.Source.CONTROLLER);
        assertThat(decision.isShadowOnly()).isTrue();
        assertThat(decision.isEnforced()).isFalse();
        assertThat(decision.isCompatibilityFallback()).isFalse();
    }

    @Test
    void logPayloadRemainsStableAndQueryable() {
        OffenseGovernanceDecision decision = OffenseGovernanceLogFactory.nullFieldPreserved(
                OffenseGovernanceDecision.Source.CONTROLLER,
                42L,
                FullUpdateCompatibilityMode.LEGACY_SHADOW,
                LocalDateTime.of(2026, 5, 8, 12, 0),
                List.of("offenseCode", "driverId")
        );

        assertThat(OffenseGovernanceLogFactory.format(decision)).isEqualTo(
                "governance=NULL_FIELD_PRESERVED rolloutMode=COMPATIBILITY semantic=FULL_UPDATE enforcement=COMPATIBILITY_FALLBACK "
                        + "source=CONTROLLER offenseId=42 updatedAt=2026-05-08T12:00 "
                        + "fields=[offenseCode,driverId] compatibilityMode=LEGACY_SHADOW"
        );
    }

    @Test
    void noOpClassificationCreatesSuppressionDecision() {
        MutationSideEffectPolicy policy = new SemanticIntentClassifier().classifyKafkaAction("update", true);
        OffenseGovernanceDecision decision = OffenseGovernanceLogFactory.noOpSuppressed(
                OffenseGovernanceDecision.Source.KAFKA,
                50L,
                "duplicate"
        );

        assertThat(policy.semanticEventType()).isEqualTo(SemanticEventType.NO_OP);
        assertThat(policy.has(MutationSideEffect.NONE)).isTrue();
        assertThat(decision.type()).isEqualTo(OffenseGovernanceDecisionType.NO_OP_SUPPRESSED);
        assertThat(decision.semanticEventType()).isEqualTo(SemanticEventType.NO_OP);
        assertThat(decision.isEnforced()).isTrue();
    }

    @Test
    void compatibilityModeDecisionMarksFallback() {
        OffenseGovernanceDecision decision = OffenseGovernanceLogFactory.legacyCompatibilityMode(
                60L,
                FullUpdateCompatibilityMode.LEGACY_SHADOW,
                null,
                List.of("processStatus")
        );

        assertThat(decision.type()).isEqualTo(OffenseGovernanceDecisionType.LEGACY_COMPATIBILITY_MODE);
        assertThat(decision.source()).isEqualTo(OffenseGovernanceDecision.Source.CONTROLLER);
        assertThat(decision.isCompatibilityFallback()).isTrue();
        assertThat(OffenseGovernanceLogFactory.format(decision))
                .contains("governance=LEGACY_COMPATIBILITY_MODE")
                .contains("rolloutMode=COMPATIBILITY")
                .contains("enforcement=COMPATIBILITY_FALLBACK")
                .contains("source=CONTROLLER");
    }

    @Test
    void staleKafkaRejectionCarriesGovernanceDecision() {
        OffenseRecordMapper offenseRecordMapper = mock(OffenseRecordMapper.class);
        OffenseRecordService service = new OffenseRecordService(
                offenseRecordMapper,
                mock(SysRequestHistoryMapper.class),
                mock(OffenseInformationSearchRepository.class),
                mock(KafkaTemplate.class),
                mock(ObjectMapper.class)
        );
        OffenseRecord current = record(70L, LocalDateTime.of(2026, 5, 8, 12, 0));
        OffenseRecord incoming = record(70L, LocalDateTime.of(2026, 5, 8, 11, 0));
        when(offenseRecordMapper.selectById(70L)).thenReturn(current);

        StaleFullUpdateRejectedException ex = assertThrows(
                StaleFullUpdateRejectedException.class,
                () -> service.updateKafkaFullUpdate(incoming)
        );

        assertThat(ex.decision().type()).isEqualTo(OffenseGovernanceDecisionType.STALE_REJECTED);
        assertThat(ex.decision().semanticEventType()).isEqualTo(SemanticEventType.FULL_UPDATE);
        assertThat(ex.decision().source()).isEqualTo(OffenseGovernanceDecision.Source.KAFKA);
        assertThat(ex.decision().isEnforced()).isTrue();
        assertThat(OffenseGovernanceLogFactory.format(ex.decision())).isEqualTo(
                "governance=STALE_REJECTED rolloutMode=ENFORCED semantic=FULL_UPDATE enforcement=ENFORCED "
                        + "source=KAFKA offenseId=70 updatedAt=2026-05-08T11:00 "
                        + "currentUpdatedAt=2026-05-08T12:00 incomingUpdatedAt=2026-05-08T11:00"
        );
    }

    private OffenseRecord record(Long offenseId, LocalDateTime updatedAt) {
        OffenseRecord record = new OffenseRecord();
        record.setOffenseId(offenseId);
        record.setUpdatedAt(updatedAt);
        return record;
    }
}
