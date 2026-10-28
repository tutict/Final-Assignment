package com.tutict.finalassignmentbackend.ai.guardrail;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AnswerTextSanitizerTest {

    @Test
    void removesRetrievedContextLabelAndKeepsCitation() {
        String answer = "根据 retrieved_context [1], 过失通知方式包含短信、APP推送和邮寄三种方式。";

        assertThat(AnswerTextSanitizer.sanitize(answer))
                .isEqualTo("根据 [1], 过失通知方式包含短信、APP推送和邮寄三种方式。");
    }

    @Test
    void removesSpacedAndHyphenatedVariants() {
        assertThat(AnswerTextSanitizer.sanitize("根据 retrieved context [4], 超过法定期限。"))
                .isEqualTo("根据 [4], 超过法定期限。");
        assertThat(AnswerTextSanitizer.sanitize("根据 retrieved-context [2], 需要材料。"))
                .isEqualTo("根据 [2], 需要材料。");
    }

    @Test
    void removesManualDocumentAndChunkIdentifiers() {
        assertThat(AnswerTextSanitizer.sanitize("根据 manual_rag_document[c-fine-payment-methods]，支持该结论 [2]。"))
                .isEqualTo("根据 支持该结论 [2]。");
        assertThat(AnswerTextSanitizer.sanitize("[1] 来源 rag_chunk_ragas_current 的内容。"))
                .isEqualTo("[1] 来源 的内容。");
    }

    @Test
    void removesContextTagsButKeepsBody() {
        assertThat(AnswerTextSanitizer.sanitize(
                        "<retrieved_context>[1] 罚款需在十五日内缴纳。</retrieved_context>"))
                .isEqualTo("[1] 罚款需在十五日内缴纳。");
    }

    @Test
    void leavesOrdinaryAnswersUntouched() {
        String answer = "In this context, [1] applies; no internal tag here.";

        assertThat(AnswerTextSanitizer.sanitize(answer)).isEqualTo(answer);
    }

    @Test
    void removesPlaceholderCitationAndKeepsNumericMarker() {
        assertThat(AnswerTextSanitizer.sanitize("根据车辆管理相关规定 [n][2] 办理过户。"))
                .isEqualTo("根据车辆管理相关规定 [2] 办理过户。");
        assertThat(AnswerTextSanitizer.sanitize("根据 [N] 规定，罚款需在十五日内缴纳。"))
                .isEqualTo("根据 规定，罚款需在十五日内缴纳。");
    }

    @Test
    void normalizesSpacingLeftByRemovedLabel() {
        assertThat(AnswerTextSanitizer.sanitize("根据  retrieved_context，[1] 罚款。"))
                .isEqualTo("根据 [1] 罚款。");
    }
}
