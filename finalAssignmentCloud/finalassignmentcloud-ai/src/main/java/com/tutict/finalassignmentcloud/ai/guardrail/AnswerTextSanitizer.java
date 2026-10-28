package com.tutict.finalassignmentcloud.ai.guardrail;

import java.util.regex.Pattern;

/**
 * Removes prompt-internal labels that small models sometimes copy into answers, while keeping
 * user-facing citation markers such as {@code [1]} intact.
 */
public final class AnswerTextSanitizer {

    private static final String LABEL =
            "(?:<\\s*/?\\s*retrieved_context\\s*>"
                    + "|retrieved[_\\- ]context"
                    + "|manual_rag_document(?:\\s*\\[[^\\]]*\\])?"
                    + "|rag_chunk(?:_[a-z0-9_]+)?(?:\\s*\\[[^\\]]*\\])?)";

    private static final Pattern LEADING_CONNECTIVE = Pattern.compile(
            "(根据|依据|按照|从|如)\\s*" + LABEL + "\\s*(?:[，,、:：]\\s*)?",
            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE
    );

    private static final Pattern INTERNAL_LABEL = Pattern.compile(
            LABEL + "\\s*(?:[，,、:：]\\s*)?",
            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE
    );

    private static final Pattern PLACEHOLDER_CITATION = Pattern.compile("\\[\\s*n\\s*\\]",
            Pattern.CASE_INSENSITIVE);
    private static final Pattern SPACE_BEFORE_PUNCTUATION = Pattern.compile("[ \\t]+([,，.。;；:：!?！？、])");
    private static final Pattern REPEATED_SPACES = Pattern.compile("[ \\t]{2,}");

    private AnswerTextSanitizer() {
    }

    public static String sanitize(String answer) {
        if (answer == null || answer.isEmpty()) {
            return answer;
        }
        String sanitized = LEADING_CONNECTIVE.matcher(answer).replaceAll("$1 ");
        sanitized = INTERNAL_LABEL.matcher(sanitized).replaceAll("");
        sanitized = PLACEHOLDER_CITATION.matcher(sanitized).replaceAll("");
        sanitized = SPACE_BEFORE_PUNCTUATION.matcher(sanitized).replaceAll("$1");
        sanitized = REPEATED_SPACES.matcher(sanitized).replaceAll(" ");
        return sanitized.strip();
    }
}
