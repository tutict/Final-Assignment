package com.tutict.finalassignmentbackend.governance.core;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class GovernanceCoreTest {

    @Test
    void semanticContractClassifiesMutatingAndNoOpEventsStably() {
        EventIntentClassifier<TestEvent, TestState> classifier = this::classify;

        MutationSideEffectPolicy workflow = classifier.classify(
                new TestEvent("WORKFLOW", false),
                new TestState("OPEN")
        );
        MutationSideEffectPolicy duplicate = classifier.classify(
                new TestEvent("WORKFLOW", true),
                new TestState("OPEN")
        );

        assertThat(workflow.mutationType()).isEqualTo(SemanticMutationType.WORKFLOW);
        assertThat(workflow.mutatesState()).isTrue();
        assertThat(workflow.reindexesSearch()).isTrue();
        assertThat(workflow.evictsCache()).isTrue();
        assertThat(workflow.requiresAfterCommit()).isTrue();
        assertThat(duplicate.mutationType()).isEqualTo(SemanticMutationType.NO_OP);
        assertThat(duplicate.duplicate()).isTrue();
        assertThat(duplicate.hasSideEffects()).isFalse();
    }

    @Test
    void sideEffectCoordinatorPreservesAfterCommitOrdering() {
        List<Runnable> afterCommitQueue = new ArrayList<>();
        SideEffectCoordinator coordinator = new SideEffectCoordinator(afterCommitQueue::add);
        List<String> observed = new ArrayList<>();
        MutationSideEffectPolicy policy = MutationSideEffectPolicy.mutating(
                SemanticMutationType.FULL_UPDATE,
                true,
                true,
                true,
                false,
                false
        );

        observed.add("db");
        coordinator.afterCommit(policy, List.of(
                () -> observed.add("kafka"),
                () -> observed.add("search"),
                () -> observed.add("cache")
        ));

        assertThat(observed).containsExactly("db");
        afterCommitQueue.forEach(Runnable::run);
        assertThat(observed).containsExactly("db", "kafka", "search", "cache");
    }

    @Test
    void governancePolicyIsDeterministicForSameInputs() {
        TestEvent event = new TestEvent("SYSTEM", false);
        TestState state = new TestState("OPEN");

        MutationSideEffectPolicy first = classify(event, state);
        MutationSideEffectPolicy second = classify(event, state);

        assertThat(first).isEqualTo(second);
        assertThat(first.mutationType()).isEqualTo(SemanticMutationType.SYSTEM);
    }

    @Test
    void noOpPolicySuppressesOrchestrationSideEffects() {
        List<Runnable> afterCommitQueue = new ArrayList<>();
        SideEffectCoordinator coordinator = new SideEffectCoordinator(afterCommitQueue::add);

        coordinator.afterCommit(MutationSideEffectPolicy.noOp(false), List.of(
                () -> {
                    throw new AssertionError("no-op side effect must not run");
                }
        ));

        assertThat(afterCommitQueue).isEmpty();
    }

    @Test
    void readWriteVocabularyKeepsProjectionAndRetrievalContractsIsolated() {
        TestAssembler assembler = new TestAssembler();

        TestReadModel readModel = assembler.toReadModel(new TestWriteModel("A-10", "private", "public reason"));
        TestRetrievalView retrievalView = new TestRetrievalView(readModel.reason());

        assertThat(readModel.privateNote()).isEqualTo("private");
        assertThat(retrievalView.retrievalSafeFields())
                .containsExactly(Map.entry("reason", "public reason"));
        assertThat(retrievalView.retrievalSafeFields()).doesNotContainKey("privateNote");
    }

    private MutationSideEffectPolicy classify(TestEvent event, TestState state) {
        if (event.duplicate()) {
            return MutationSideEffectPolicy.noOp(true);
        }
        return switch (event.kind()) {
            case "WORKFLOW" -> MutationSideEffectPolicy.mutating(
                    SemanticMutationType.WORKFLOW,
                    false,
                    true,
                    true,
                    false,
                    false
            );
            case "SYSTEM" -> MutationSideEffectPolicy.mutating(
                    SemanticMutationType.SYSTEM,
                    false,
                    true,
                    true,
                    false,
                    false
            );
            default -> MutationSideEffectPolicy.noOp(false);
        };
    }

    private record TestEvent(String kind, boolean duplicate) {
    }

    private record TestState(String status) {
    }

    private record TestWriteModel(
            String number,
            String privateNote,
            String reason
    ) implements GovernanceVocabulary.WriteModel {
    }

    private record TestReadModel(
            String number,
            String privateNote,
            String reason
    ) implements GovernanceVocabulary.ReadModel {
    }

    private record TestRetrievalView(String reason) implements GovernanceVocabulary.RetrievalSafeView {

        @Override
        public Map<String, String> retrievalSafeFields() {
            return Map.of("reason", reason);
        }
    }

    private static final class TestAssembler
            implements GovernanceVocabulary.ProjectionAssembler<TestWriteModel, TestReadModel> {

        @Override
        public TestReadModel toReadModel(TestWriteModel source) {
            return new TestReadModel(source.number(), source.privateNote(), source.reason());
        }
    }
}
