package finalassignmentbackend.ai.guardrail;

import finalassignmentbackend.ai.chat.ChatStreamEvent;
import finalassignmentbackend.rag.service.RagQueryService.RetrievedChunk;
import io.smallrye.mutiny.Multi;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;

class GuardrailStageTest {

    private final GuardrailStage stage = new GuardrailStage();
    private final AnswerGroundingPolicy policy = new AnswerGroundingPolicy();

    @Test
    void sanitizesInternalLabelsWhenNotEnforcing() {
        stage.policy = policy;

        List<ChatStreamEvent> events = run(tokens("根据 <retrieved_context>，罚款需在十五日内缴纳。"), null);

        assertEquals(1, events.size());
        assertEquals("根据 罚款需在十五日内缴纳。", events.getFirst().token());
    }

    @Test
    void uncitedAnswerIsRefusedWithCanonicalText() {
        policy.enforcementEnabled = true;
        stage.policy = policy;

        List<ChatStreamEvent> events = run(tokens("罚款需在十五日内缴纳。"), null);

        assertEquals(1, events.size());
        assertEquals(AnswerGroundingPolicy.UNCITED_ANSWER, events.getFirst().token());
        assertEquals("msg-1", events.getFirst().messageId());
    }

    @Test
    void citedAnswerReplaysOriginalTokens() {
        policy.enforcementEnabled = true;
        stage.policy = policy;
        List<ChatStreamEvent> input = List.of(
                ChatStreamEvent.token("s1", "msg-1", "罚款"),
                ChatStreamEvent.token("s1", "msg-1", "需在十五日内缴纳 [1]。"));

        List<ChatStreamEvent> events = run(Multi.createFrom().iterable(input), null);

        assertEquals(input, events);
    }

    @Test
    void repairRunsOnceAndKeepsTheFirstMessageId() {
        policy.enforcementEnabled = true;
        stage.policy = policy;
        AtomicInteger repairCalls = new AtomicInteger();

        List<ChatStreamEvent> events = run(tokens("罚款十五日。"), () -> {
            repairCalls.incrementAndGet();
            return Multi.createFrom().items(
                    new ChatStreamEvent("token", "other-session", "other-message",
                            "罚款需在十五日内缴纳 [1]。", null, "2026-01-01T00:00:00Z"));
        });

        assertEquals(1, repairCalls.get());
        assertEquals(1, events.size());
        assertEquals("罚款需在十五日内缴纳 [1]。", events.getFirst().token());
        assertEquals("s1", events.getFirst().sessionKey());
        assertEquals("msg-1", events.getFirst().messageId());
    }

    @Test
    void failedRepairFallsBackToUncitedRefusal() {
        policy.enforcementEnabled = true;
        stage.policy = policy;

        List<ChatStreamEvent> events = run(
                tokens("罚款十五日。"),
                () -> Multi.createFrom().failure(new IllegalStateException("model down")));

        assertEquals(AnswerGroundingPolicy.UNCITED_ANSWER, events.getFirst().token());
    }

    @Test
    void noSourcesRefusesWithNoSourceAnswer() {
        policy.enforcementEnabled = true;
        stage.policy = policy;

        List<ChatStreamEvent> events = stage.apply(tokens("罚款十五日。"), "罚款怎么缴？", List.of(), null)
                .collect().asList().await().atMost(Duration.ofSeconds(5));

        assertEquals(AnswerGroundingPolicy.NO_SOURCE_ANSWER, events.getFirst().token());
    }

    @Test
    void nonTextEventsPassThroughUntouched() {
        policy.enforcementEnabled = true;
        stage.policy = policy;
        ChatStreamEvent error = ChatStreamEvent.error("s1", "msg-1", "模型生成失败");
        ChatStreamEvent token = ChatStreamEvent.token("s1", "msg-1", "未引用回答");

        List<ChatStreamEvent> events = run(Multi.createFrom().items(error, token), null);

        assertEquals(2, events.size());
        assertSame(error, events.get(0));
        assertSame(token, events.get(1));
        assertNotEquals(AnswerGroundingPolicy.UNCITED_ANSWER, events.get(1).token());
    }

    @Test
    void verifierRefusalReplacesAnswer() {
        stage.policy = policy;
        TopicGroundingVerifier verifier = new TopicGroundingVerifier() {
            @Override
            public GroundingDecision verify(
                    String question,
                    String answer,
                    List<RetrievedChunk> sources
            ) {
                return GroundingDecision.refused(AnswerGroundingPolicy.NO_SOURCE_ANSWER, "topic_mismatch");
            }
        };
        stage.verifier = verifier;

        List<ChatStreamEvent> events = stage.apply(
                        tokens("罚款需在十五日内缴纳 [1]。"),
                        "车辆报废流程是什么？",
                        List.of(source("mannual", "报废流程...")),
                        null)
                .collect().asList().await().atMost(Duration.ofSeconds(5));

        assertEquals(AnswerGroundingPolicy.NO_SOURCE_ANSWER, events.getFirst().token());
    }

    @Test
    void fallbackTokenSkipsJudgement() {
        policy.enforcementEnabled = true;
        stage.policy = policy;
        ChatStreamEvent fallback = new ChatStreamEvent("token", "s1", "msg-1", "AI 暂时不可用",
                Map.of("isFallback", true), "2026-01-01T00:00:00Z");

        List<ChatStreamEvent> events = run(Multi.createFrom().item(fallback), null);

        assertEquals("AI 暂时不可用", events.getFirst().token());
        assertTrue(events.getFirst().payload() instanceof Map);
    }

    private List<ChatStreamEvent> run(Multi<ChatStreamEvent> input,
                                      java.util.function.Supplier<Multi<ChatStreamEvent>> repair) {
        return stage.apply(input, "罚款怎么缴？", List.of(source("manual-1", "罚款应在十五日内缴纳。")), repair)
                .collect().asList().await().atMost(Duration.ofSeconds(5));
    }

    private static Multi<ChatStreamEvent> tokens(String... parts) {
        List<ChatStreamEvent> events = new java.util.ArrayList<>();
        for (String part : parts) {
            events.add(ChatStreamEvent.token("s1", "msg-1", part));
        }
        return Multi.createFrom().iterable(events);
    }

    private static RetrievedChunk source(String sourceId, String content) {
        return new RetrievedChunk("c1", "d1", sourceId, content, "罚款规定", "MANUAL", null, 1.0);
    }
}
