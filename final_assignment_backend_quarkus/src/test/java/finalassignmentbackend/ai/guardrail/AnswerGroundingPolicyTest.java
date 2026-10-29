package finalassignmentbackend.ai.guardrail;

import finalassignmentbackend.rag.service.RagQueryService.RetrievedChunk;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AnswerGroundingPolicyTest {

    private final AnswerGroundingPolicy policy = new AnswerGroundingPolicy();

    @Test
    void disabledPolicyAllowsUncitedAnswers() {
        assertTrue(policy.evaluate("罚款十五日。", sources()).grounded());
    }

    @Test
    void blankAnswerIsNotJudged() {
        policy.enforcementEnabled = true;

        assertTrue(policy.evaluate("   ", List.of()).grounded());
        assertTrue(policy.evaluate(null, List.of()).grounded());
    }

    @Test
    void missingSourcesRefuseWithNoSourceAnswer() {
        policy.enforcementEnabled = true;

        GroundingDecision decision = policy.evaluate("罚款十五日。", List.of());

        assertFalse(decision.grounded());
        assertEquals("no_sources", decision.reason());
        assertEquals(AnswerGroundingPolicy.NO_SOURCE_ANSWER, decision.answer());
    }

    @Test
    void uncitedAnswerIsRefused() {
        policy.enforcementEnabled = true;

        GroundingDecision decision = policy.evaluate("罚款十五日。", sources());

        assertFalse(decision.grounded());
        assertEquals("missing_citation", decision.reason());
        assertEquals(AnswerGroundingPolicy.UNCITED_ANSWER, decision.answer());
    }

    @Test
    void numericCitationInRangeIsAccepted() {
        policy.enforcementEnabled = true;

        assertTrue(policy.evaluate("罚款需在十五日内缴纳 [1]。", sources()).grounded());
        assertTrue(policy.evaluate("罚款需在十五日内缴纳【1】。", sources()).grounded());
        assertTrue(policy.evaluate("两项要求 [1，2]。", sources()).grounded());
    }

    @Test
    void numericCitationOutOfRangeDoesNotCount() {
        policy.enforcementEnabled = true;

        assertFalse(policy.evaluate("罚款需在十五日内缴纳 [9]。", sources()).grounded());
        assertFalse(policy.evaluate("罚款需在十五日内缴纳 [0]。", sources()).grounded());
    }

    @Test
    void distinctiveTitleCountsAsCitation() {
        policy.enforcementEnabled = true;

        assertTrue(policy.evaluate("依据《道路交通安全法》第八十九条，罚款十五日。", sources()).grounded());
    }

    @Test
    void bareNumericIdentifierDoesNotCountAsCitation() {
        policy.enforcementEnabled = true;
        List<RetrievedChunk> numeric = List.of(
                new RetrievedChunk("c1", "12", "7", "罚款十五日。", "标题", "MANUAL", null, 1.0));

        assertFalse(policy.evaluate("罚款十五日，依据第 7 条。", numeric).grounded());
    }

    private static List<RetrievedChunk> sources() {
        return List.of(new RetrievedChunk(
                "c1", "doc-1", "manual-1", "罚款应在十五日内缴纳。", "道路交通安全法", "MANUAL", null, 1.0));
    }
}
