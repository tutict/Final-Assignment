package com.tutict.finalassignmentbackend.offense.governance;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.statemachine.states.OffenseProcessState;
import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;
import com.tutict.finalassignmentbackend.kafkaListener.OffenseRecordKafkaListener;
import com.tutict.finalassignmentbackend.mapper.offense.OffenseRecordMapper;
import com.tutict.finalassignmentbackend.mapper.system.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.OffenseInformationSearchRepository;
import com.tutict.finalassignmentbackend.service.offense.OffenseRecordService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.lang.reflect.Method;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class OffenseFullUpdateEnforcementTest {

    @AfterEach
    void clearTransactionSynchronization() {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    @Test
    void staleKafkaFullUpdateIsRejectedBeforeDbMutation() {
        OffenseRecordMapper offenseRecordMapper = mock(OffenseRecordMapper.class);
        OffenseInformationSearchRepository searchRepository = mock(OffenseInformationSearchRepository.class);
        OffenseRecordService service = service(offenseRecordMapper, searchRepository);
        OffenseRecord current = baseRecord(10L);
        current.setUpdatedAt(LocalDateTime.of(2026, 5, 8, 12, 0));
        OffenseRecord incoming = baseRecord(10L);
        incoming.setUpdatedAt(LocalDateTime.of(2026, 5, 8, 11, 0));
        when(offenseRecordMapper.selectById(10L)).thenReturn(current);

        assertThatThrownBy(() -> service.updateKafkaFullUpdate(incoming))
                .isInstanceOf(StaleFullUpdateRejectedException.class)
                .hasMessageContaining("Stale Offense FULL_UPDATE rejected");

        verify(offenseRecordMapper).selectById(10L);
        verify(offenseRecordMapper, never()).updateById(any(OffenseRecord.class));
        verifyNoInteractions(searchRepository);
    }

    @Test
    void nonStaleKafkaFullUpdateUsesGuardedMergeAndIndexesAfterCommit() {
        TransactionSynchronizationManager.initSynchronization();
        OffenseRecordMapper offenseRecordMapper = mock(OffenseRecordMapper.class);
        OffenseInformationSearchRepository searchRepository = mock(OffenseInformationSearchRepository.class);
        OffenseRecordService service = service(offenseRecordMapper, searchRepository);
        OffenseRecord current = baseRecord(20L);
        current.setOffenseNumber("OF-020");
        current.setOffenseDescription("current description");
        current.setProcessStatus(OffenseProcessState.PROCESSED.getCode());
        current.setUpdatedAt(LocalDateTime.of(2026, 5, 8, 12, 0));
        OffenseRecord incoming = baseRecord(20L);
        incoming.setOffenseNumber("STALE-NUMBER");
        incoming.setOffenseCode("NEW-CODE");
        incoming.setOffenseDescription(null);
        incoming.setProcessStatus(OffenseProcessState.UNPROCESSED.getCode());
        incoming.setUpdatedAt(LocalDateTime.of(2026, 5, 8, 12, 1));
        when(offenseRecordMapper.selectById(20L)).thenReturn(current);
        when(offenseRecordMapper.updateById(any(OffenseRecord.class))).thenReturn(1);

        OffenseRecord updated = service.updateKafkaFullUpdate(incoming);

        ArgumentCaptor<OffenseRecord> captor = ArgumentCaptor.forClass(OffenseRecord.class);
        verify(offenseRecordMapper).updateById(captor.capture());
        assertThat(updated).isSameAs(captor.getValue());
        assertThat(captor.getValue().getOffenseId()).isEqualTo(20L);
        assertThat(captor.getValue().getOffenseNumber()).isEqualTo("OF-020");
        assertThat(captor.getValue().getOffenseCode()).isEqualTo("NEW-CODE");
        assertThat(captor.getValue().getOffenseDescription()).isEqualTo("current description");
        assertThat(captor.getValue().getProcessStatus()).isEqualTo(OffenseProcessState.PROCESSED.getCode());
        verify(searchRepository, never()).save(any());

        runAfterCommitSynchronizations();
        verify(searchRepository).save(any());
    }

    @Test
    void fullUpdatePolicyReportsImmutableNullAndWorkflowGovernance() {
        FullUpdateMergePolicy policy = new FullUpdateMergePolicy();
        OffenseRecord current = baseRecord(30L);
        current.setOffenseNumber("OF-030");
        current.setOffenseDescription("current description");
        current.setProcessStatus(OffenseProcessState.PROCESSED.getCode());
        current.setUpdatedAt(LocalDateTime.of(2026, 5, 8, 12, 0));
        OffenseRecord incoming = baseRecord(30L);
        incoming.setOffenseNumber("BAD-NUMBER");
        incoming.setOffenseDescription(null);
        incoming.setProcessStatus(OffenseProcessState.UNPROCESSED.getCode());
        incoming.setUpdatedAt(LocalDateTime.of(2026, 5, 8, 12, 1));

        FullUpdateMergePolicy.MergeResult result =
                policy.merge(current, incoming, FullUpdateCompatibilityMode.GUARDED_COMPATIBILITY);

        assertThat(result.mergedRecord().getOffenseNumber()).isEqualTo("OF-030");
        assertThat(result.mergedRecord().getOffenseDescription()).isEqualTo("current description");
        assertThat(result.mergedRecord().getProcessStatus()).isEqualTo(OffenseProcessState.PROCESSED.getCode());
        assertThat(result.nullPreservedFields()).contains("offenseDescription");
        assertThat(result.immutablePreservedFields()).contains("offenseNumber");
        assertThat(result.workflowSuppressedFields()).contains("processStatus", "updatedAt");
    }

    @Test
    void controllerUpdateRemainsCompatibilityMode() {
        TransactionSynchronizationManager.initSynchronization();
        OffenseRecordMapper offenseRecordMapper = mock(OffenseRecordMapper.class);
        OffenseInformationSearchRepository searchRepository = mock(OffenseInformationSearchRepository.class);
        OffenseRecordService service = service(offenseRecordMapper, searchRepository);
        OffenseRecord current = baseRecord(40L);
        current.setUpdatedAt(LocalDateTime.of(2026, 5, 8, 12, 0));
        OffenseRecord incoming = baseRecord(40L);
        incoming.setOffenseCode("LEGACY-CONTROLLER-CODE");
        incoming.setProcessStatus(OffenseProcessState.UNPROCESSED.getCode());
        incoming.setUpdatedAt(LocalDateTime.of(2026, 5, 8, 11, 0));
        when(offenseRecordMapper.selectById(40L)).thenReturn(current);
        when(offenseRecordMapper.updateById(any(OffenseRecord.class))).thenReturn(1);

        OffenseRecord updated = service.updateOffenseRecord(incoming);

        ArgumentCaptor<OffenseRecord> captor = ArgumentCaptor.forClass(OffenseRecord.class);
        verify(offenseRecordMapper).updateById(captor.capture());
        assertThat(updated).isSameAs(incoming);
        assertThat(captor.getValue()).isSameAs(incoming);
        assertThat(captor.getValue().getOffenseCode()).isEqualTo("LEGACY-CONTROLLER-CODE");
        assertThat(captor.getValue().getProcessStatus()).isEqualTo(OffenseProcessState.UNPROCESSED.getCode());
    }

    @Test
    void staleKafkaListenerSuppressionDoesNotMarkSuccessOrFailure() throws Exception {
        OffenseRecordService service = mock(OffenseRecordService.class);
        ObjectMapper objectMapper = mock(ObjectMapper.class);
        OffenseRecordKafkaListener listener = new OffenseRecordKafkaListener(service, objectMapper);
        OffenseRecord payload = baseRecord(50L);
        when(objectMapper.readValue("{}", OffenseRecord.class)).thenReturn(payload);
        when(service.shouldSkipProcessing("stale-key")).thenReturn(false);
        when(service.updateKafkaFullUpdate(payload)).thenThrow(new StaleFullUpdateRejectedException(50L));

        Method method = OffenseRecordKafkaListener.class.getDeclaredMethod(
                "processMessage", String.class, String.class, String.class);
        method.setAccessible(true);
        method.invoke(listener, "stale-key", "{}", "update");

        verify(service).updateKafkaFullUpdate(payload);
        verify(service, never()).markHistorySuccess(any(), any());
        verify(service, never()).markHistoryFailure(any(), any());
    }

    @Test
    void noOpPolicyStillSuppressesAllSideEffects() {
        TransactionSynchronizationManager.initSynchronization();
        OffenseSideEffectCoordinator coordinator = new OffenseSideEffectCoordinator(new AfterCommitBoundary());
        MutationSideEffectPolicy noOp = new SemanticIntentClassifier().classifyDuplicate();
        List<String> observed = new ArrayList<>();

        coordinator.publishKafkaLegacy(noOp, () -> observed.add("legacyKafka"));
        coordinator.publishKafkaAfterCommit(noOp, () -> observed.add("afterCommitKafka"));
        coordinator.indexAfterCommit(noOp, () -> observed.add("index"));
        coordinator.readRepairNow(noOp, () -> observed.add("readRepair"));

        assertThat(observed).isEmpty();
        assertThat(TransactionSynchronizationManager.getSynchronizations()).isEmpty();
    }

    private OffenseRecordService service(OffenseRecordMapper offenseRecordMapper,
                                         OffenseInformationSearchRepository searchRepository) {
        return new OffenseRecordService(
                offenseRecordMapper,
                mock(SysRequestHistoryMapper.class),
                searchRepository,
                mock(KafkaTemplate.class),
                mock(ObjectMapper.class)
        );
    }

    private OffenseRecord baseRecord(Long offenseId) {
        OffenseRecord record = new OffenseRecord();
        record.setOffenseId(offenseId);
        record.setOffenseNumber("OF-" + offenseId);
        record.setOffenseCode("OLD-CODE");
        record.setOffenseTime(LocalDateTime.of(2026, 5, 8, 10, 0));
        record.setProcessStatus(OffenseProcessState.PROCESSED.getCode());
        return record;
    }

    private void runAfterCommitSynchronizations() {
        List<TransactionSynchronization> synchronizations = new ArrayList<>(
                TransactionSynchronizationManager.getSynchronizations()
        );
        synchronizations.forEach(TransactionSynchronization::afterCommit);
    }
}
