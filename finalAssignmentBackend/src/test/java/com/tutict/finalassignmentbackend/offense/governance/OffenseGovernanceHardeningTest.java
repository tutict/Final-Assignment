package com.tutict.finalassignmentbackend.offense.governance;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.statemachine.states.OffenseProcessState;
import com.tutict.finalassignmentbackend.controller.business.OffenseInformationController;
import com.tutict.finalassignmentbackend.dto.request.OffenseCreateRequest;
import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;
import com.tutict.finalassignmentbackend.mapper.offense.OffenseRecordMapper;
import com.tutict.finalassignmentbackend.mapper.system.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.OffenseInformationSearchRepository;
import com.tutict.finalassignmentbackend.service.offense.OffenseRecordService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;

class OffenseGovernanceHardeningTest {

    @AfterEach
    void clearTransactionSynchronization() {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    @Test
    void noOpPolicySuppressesAllCoordinatorSideEffects() {
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

    @Test
    void createKafkaPublishIsDeferredUntilAfterCommitBoundary() throws Exception {
        TransactionSynchronizationManager.initSynchronization();
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
        OffenseRecord offenseRecord = new OffenseRecord();
        when(objectMapper.writeValueAsString(offenseRecord)).thenReturn("{\"offenseId\":10}");

        service.publishCreateKafkaAfterCommit("create-key", offenseRecord);

        verifyNoInteractions(kafkaTemplate);
        runAfterCommitSynchronizations();
        verify(kafkaTemplate).send("offense_record_create", "create-key", "{\"offenseId\":10}");
    }

    @Test
    void createDuplicateNoOpReturnsBeforeMutationSideEffects() {
        OffenseRecordService service = mock(OffenseRecordService.class);
        OffenseInformationController controller = new OffenseInformationController(service);
        OffenseCreateRequest request = new OffenseCreateRequest();
        when(service.shouldSkipProcessing("dup-key")).thenReturn(true);

        ResponseEntity<?> response = controller.create(request, "dup-key");

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.ALREADY_REPORTED);
        verify(service).shouldSkipProcessing("dup-key");
        verify(service, never()).checkAndInsertIdempotency(any(), any(), any());
        verify(service, never()).createOffenseRecord(any());
        verify(service, never()).markHistorySuccess(any(), any());
        verify(service, never()).publishCreateKafkaAfterCommit(any(), any());
        verifyNoMoreInteractions(service);
    }

    @Test
    void createControllerPublishesKafkaOnlyAfterSuccessfulCreateAndHistorySuccess() {
        OffenseRecordService service = mock(OffenseRecordService.class);
        OffenseInformationController controller = new OffenseInformationController(service);
        OffenseCreateRequest request = new OffenseCreateRequest();
        OffenseRecord saved = new OffenseRecord();
        saved.setOffenseId(10L);
        when(service.shouldSkipProcessing("create-key")).thenReturn(false);
        when(service.createOffenseRecord(any(OffenseRecord.class))).thenReturn(saved);

        ResponseEntity<?> response = controller.create(request, "create-key");

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isSameAs(saved);
        ArgumentCaptor<OffenseRecord> mappedRecord = ArgumentCaptor.forClass(OffenseRecord.class);
        InOrder order = inOrder(service);
        order.verify(service).shouldSkipProcessing("create-key");
        order.verify(service).checkAndInsertIdempotency(eq("create-key"), mappedRecord.capture(), eq("create"));
        order.verify(service).createOffenseRecord(mappedRecord.getValue());
        order.verify(service).markHistorySuccess("create-key", 10L);
        order.verify(service).publishCreateKafkaAfterCommit("create-key", saved);
        order.verifyNoMoreInteractions();
    }

    @Test
    void workflowPolicyAndServiceDoNotPublishKafka() {
        TransactionSynchronizationManager.initSynchronization();
        SemanticIntentClassifier classifier = new SemanticIntentClassifier();
        MutationSideEffectPolicy workflow = classifier.classifyWorkflow();
        assertThat(workflow.semanticEventType()).isEqualTo(SemanticEventType.WORKFLOW);
        assertThat(workflow.has(MutationSideEffect.KAFKA_PUBLISH)).isFalse();
        assertThat(workflow.has(MutationSideEffect.DB_MUTATION)).isTrue();
        assertThat(workflow.has(MutationSideEffect.ES_INDEX)).isTrue();

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
        OffenseRecord existing = new OffenseRecord();
        existing.setOffenseId(20L);
        existing.setOffenseCode("CURRENT-CODE");
        existing.setProcessStatus(OffenseProcessState.UNPROCESSED.getCode());
        when(offenseRecordMapper.selectById(20L)).thenReturn(existing);
        when(offenseRecordMapper.update(org.mockito.ArgumentMatchers.isNull(), org.mockito.ArgumentMatchers.any())).thenReturn(1);

        OffenseRecord updated = service.updateProcessStatus(20L, OffenseProcessState.PROCESSING);

        assertThat(updated.getProcessStatus()).isEqualTo(OffenseProcessState.PROCESSING.getCode());
        verify(offenseRecordMapper).update(org.mockito.ArgumentMatchers.isNull(), org.mockito.ArgumentMatchers.any());
        assertThat(updated.getOffenseId()).isEqualTo(20L);
        assertThat(updated.getOffenseCode()).isEqualTo("CURRENT-CODE");
        assertThat(updated.getProcessStatus()).isEqualTo(OffenseProcessState.PROCESSING.getCode());
        verifyNoInteractions(kafkaTemplate);
        verify(searchRepository, never()).save(any());

        runAfterCommitSynchronizations();
        verify(searchRepository).save(any());
        verifyNoInteractions(kafkaTemplate);
    }

    @Test
    void kafkaUpdateShadowComparisonDoesNotEnforceMergeYet() {
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
        OffenseRecord current = new OffenseRecord();
        current.setOffenseId(30L);
        current.setOffenseNumber("OF-030");
        current.setProcessStatus("Processed");
        OffenseRecord incoming = new OffenseRecord();
        incoming.setOffenseId(30L);
        incoming.setOffenseNumber("STALE-NUMBER");
        incoming.setProcessStatus("Unprocessed");
        when(offenseRecordMapper.selectById(30L)).thenReturn(current);

        service.shadowCompareKafkaUpdateMerge(incoming);

        verify(offenseRecordMapper).selectById(30L);
        verify(offenseRecordMapper, never()).updateById(any(OffenseRecord.class));
        verifyNoInteractions(searchRepository, kafkaTemplate);
    }

    private void runAfterCommitSynchronizations() {
        List<TransactionSynchronization> synchronizations = new ArrayList<>(
                TransactionSynchronizationManager.getSynchronizations()
        );
        synchronizations.forEach(TransactionSynchronization::afterCommit);
    }
}
