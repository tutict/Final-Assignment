package com.tutict.finalassignmentbackend.ai.guardrail;

import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class AnswerGroundingPolicyTest {

    private final AnswerGroundingPolicy policy = new AnswerGroundingPolicy(true);

    @Test
    void refusesWhenNoSourcesWereRetrieved() {
        GroundingDecision decision = policy.evaluate("罚款可以分期缴纳 [1]", List.of());

        assertThat(decision.grounded()).isFalse();
        assertThat(decision.reason()).isEqualTo("no_sources");
        assertThat(decision.answer()).isEqualTo(AnswerGroundingPolicy.NO_SOURCE_ANSWER);
    }

    @Test
    void refusesUncitedAnswerWhenSourcesExist() {
        GroundingDecision decision = policy.evaluate("罚款可以分期缴纳。", List.of(source()));

        assertThat(decision.grounded()).isFalse();
        assertThat(decision.reason()).isEqualTo("missing_citation");
        assertThat(decision.answer()).isEqualTo(AnswerGroundingPolicy.UNCITED_ANSWER);
    }

    @Test
    void allowsNumericCitationWithinRange() {
        GroundingDecision decision = policy.evaluate("需要在十五日内缴纳 [1]", List.of(source()));

        assertThat(decision.grounded()).isTrue();
        assertThat(decision.answer()).isEqualTo("需要在十五日内缴纳 [1]");
    }

    @Test
    void rejectsCitationIndexOutsideSourceRange() {
        GroundingDecision decision = policy.evaluate("see [9] for details", List.of(source()));

        assertThat(decision.grounded()).isFalse();
        assertThat(decision.reason()).isEqualTo("missing_citation");
    }

    @Test
    void allowsReferenceByDocumentIdOrTitle() {
        assertThat(policy.evaluate("see doc-1 for details", List.of(source())).grounded()).isTrue();
        assertThat(policy.evaluate("the Fine Payment Guide explains it", List.of(source())).grounded()).isTrue();
    }

    @Test
    void allowsBlankAnswersToPassThrough() {
        assertThat(policy.evaluate("", List.of(source())).grounded()).isTrue();
        assertThat(policy.evaluate(null, List.of(source())).grounded()).isTrue();
    }

    @Test
    void disabledPolicyAlwaysAllows() {
        AnswerGroundingPolicy disabled = new AnswerGroundingPolicy(false);

        assertThat(disabled.isEnforcementEnabled()).isFalse();
        assertThat(disabled.evaluate("anything", List.of()).grounded()).isTrue();
    }

    @Test
    void doesNotTreatShortNumericRowIdAsCitation() {
        RetrievalResult numbered = new RetrievalResult(
                "chunk-2", "doc-2", "content", "Fine Payment Guide",
                "BUSINESS", "docs", "12", "body", "/fine/payment",
                0.2, 0.6, 0.84, Map.of());

        GroundingDecision decision = policy.evaluate("\u7f5a\u6b3e 12 \u5143", List.of(numbered));

        assertThat(decision.grounded()).isFalse();
        assertThat(decision.reason()).isEqualTo("missing_citation");
    }

    @Test
    void allowsTwoCharacterHanTitleAsCitation() {
        RetrievalResult hanTitle = new RetrievalResult(
                "chunk-3", "doc-3", "content", "\u8bb0\u5206",
                "BUSINESS", "docs", "7", "body", "/license/points",
                0.2, 0.6, 0.84, Map.of());

        assertThat(policy.evaluate("\u8bb0\u5206\u5468\u671f\u4e3a\u5341\u4e8c\u4e2a\u6708", List.of(hanTitle)).grounded())
                .isTrue();
    }

    private static RetrievalResult source() {
        return new RetrievalResult(
                "chunk-1",
                "doc-1",
                "罚款需在十五日内缴纳。",
                "Fine Payment Guide",
                "BUSINESS",
                "docs",
                "7",
                "body",
                "/fine/payment",
                0.2,
                0.6,
                0.84,
                Map.of()
        );
    }
}
