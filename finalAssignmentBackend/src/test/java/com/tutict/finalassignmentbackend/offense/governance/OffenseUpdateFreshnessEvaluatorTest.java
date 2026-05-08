package com.tutict.finalassignmentbackend.offense.governance;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.statemachine.states.OffenseProcessState;
import com.tutict.finalassignmentbackend.entity.OffenseRecord;
import com.tutict.finalassignmentbackend.mapper.OffenseRecordMapper;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.OffenseInformationSearchRepository;
import com.tutict.finalassignmentbackend.service.OffenseRecordService;
import org.junit.jupiter.api.Test;
import org.springframework.kafka.core.KafkaTemplate;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class OffenseUpdateFreshnessEvaluatorTest {

    private final OffenseUpdateFreshnessEvaluator evaluator = new OffenseUpdateFreshnessEvaluator();

    @Test
    void staleWorkflowIsRejectedWhenProcessTimeMovesBackward() {
        OffenseRecord current = record(10L);
        current.setProcessStatus(OffenseProcessState.PROCESSED.getCode());
        current.setProcessTime(LocalDateTime.of(2026, 5, 8, 12, 0));

        OffenseRecord incoming = record(10L);
        incoming.setProcessStatus(OffenseProcessState.PROCESSED.getCode());
        incoming.setProcessTime(LocalDateTime.of(2026, 5, 8, 11, 59));

        assertThat(evaluator.evaluate(current, incoming, SemanticEventType.WORKFLOW))
                .isEqualTo(OffenseStaleUpdatePolicy.Decision.REJECT_STALE);
    }

    @Test
    void staleWorkflowIsRejectedBeforePersistenceWhenStatusDowngrades() {
        OffenseRecordMapper offenseRecordMapper = mock(OffenseRecordMapper.class);
        SysRequestHistoryMapper historyMapper = mock(SysRequestHistoryMapper.class);
        OffenseInformationSearchRepository searchRepository = mock(OffenseInformationSearchRepository.class);
        KafkaTemplate<String, String> kafkaTemplate = mock(KafkaTemplate.class);
        ObjectMapper objectMapper = mock(ObjectMapper.class);
        OffenseRecordService service = new OffenseRecordService(
                offenseRecordMapper,
                historyMapper,
                searchRepository,
                kafkaTemplate,
                objectMapper
        );
        OffenseRecord current = record(20L);
        current.setProcessStatus(OffenseProcessState.PROCESSED.getCode());
        when(offenseRecordMapper.selectById(20L)).thenReturn(current);

        assertThatThrownBy(() -> service.updateProcessStatus(20L, OffenseProcessState.PROCESSING))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Stale Offense workflow update rejected");

        verify(offenseRecordMapper).selectById(20L);
        verify(offenseRecordMapper, never()).updateById(any(OffenseRecord.class));
        verifyNoInteractions(searchRepository, kafkaTemplate);
    }

    @Test
    void newerWorkflowIsAccepted() {
        OffenseRecord current = record(30L);
        current.setProcessStatus(OffenseProcessState.UNPROCESSED.getCode());
        current.setProcessTime(LocalDateTime.of(2026, 5, 8, 10, 0));

        OffenseRecord incoming = record(30L);
        incoming.setProcessStatus(OffenseProcessState.PROCESSING.getCode());
        incoming.setProcessTime(LocalDateTime.of(2026, 5, 8, 10, 1));

        assertThat(evaluator.evaluate(current, incoming, SemanticEventType.WORKFLOW))
                .isEqualTo(OffenseStaleUpdatePolicy.Decision.ACCEPT);
    }

    @Test
    void staleKafkaFullUpdateIsDetectedInShadowMode() {
        OffenseRecord current = record(40L);
        current.setUpdatedAt(LocalDateTime.of(2026, 5, 8, 14, 0));

        OffenseRecord incoming = record(40L);
        incoming.setUpdatedAt(LocalDateTime.of(2026, 5, 8, 13, 0));

        assertThat(evaluator.evaluate(current, incoming, SemanticEventType.FULL_UPDATE))
                .isEqualTo(OffenseStaleUpdatePolicy.Decision.SHADOW_ONLY);
    }

    @Test
    void equalTimestampDuplicateIsAcceptedSafely() {
        LocalDateTime timestamp = LocalDateTime.of(2026, 5, 8, 15, 0);
        OffenseRecord current = record(50L);
        current.setProcessStatus(OffenseProcessState.PROCESSED.getCode());
        current.setProcessTime(timestamp);

        OffenseRecord incoming = record(50L);
        incoming.setProcessStatus(OffenseProcessState.PROCESSED.getCode());
        incoming.setProcessTime(timestamp);

        assertThat(evaluator.evaluate(current, incoming, SemanticEventType.WORKFLOW))
                .isEqualTo(OffenseStaleUpdatePolicy.Decision.ACCEPT);
    }

    @Test
    void validFullUpdateIsAcceptedWithoutFalseStaleRejection() {
        OffenseRecord current = record(60L);
        current.setUpdatedAt(LocalDateTime.of(2026, 5, 8, 16, 0));

        OffenseRecord incoming = record(60L);
        incoming.setUpdatedAt(LocalDateTime.of(2026, 5, 8, 16, 1));

        assertThat(evaluator.evaluate(current, incoming, SemanticEventType.FULL_UPDATE))
                .isEqualTo(OffenseStaleUpdatePolicy.Decision.ACCEPT);
    }

    private OffenseRecord record(Long offenseId) {
        OffenseRecord record = new OffenseRecord();
        record.setOffenseId(offenseId);
        return record;
    }
}
