package finalassignmentbackend.ai.guardrail;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class AnswerTextSanitizerTest {

    @Test
    void keepsNumericCitationMarkers() {
        assertEquals("罚款需在十五日内缴纳 [1]。", AnswerTextSanitizer.sanitize("罚款需在十五日内缴纳 [1]。"));
    }

    @Test
    void stripsLeadingConnectiveAndContextLabel() {
        assertEquals(
                "根据 罚款需在十五日内缴纳 [1]。",
                AnswerTextSanitizer.sanitize("根据 <retrieved_context>，罚款需在十五日内缴纳 [1]。"));
    }

    @Test
    void stripsInternalLabelsAnywhere() {
        assertEquals(
                "罚款 需在十五日内缴纳。",
                AnswerTextSanitizer.sanitize("罚款 manual_rag_document [c1] 需在十五日内缴纳。"));
    }

    @Test
    void stripsPlaceholderCitations() {
        assertEquals("结论。", AnswerTextSanitizer.sanitize("结论 [n] 。"));
    }

    @Test
    void collapsesSpacesBeforePunctuation() {
        assertEquals("罚款，十五日。", AnswerTextSanitizer.sanitize("罚款 ，十五日 。"));
    }

    @Test
    void toleratesNullAndEmpty() {
        assertNull(AnswerTextSanitizer.sanitize(null));
        assertEquals("", AnswerTextSanitizer.sanitize(""));
    }
}
