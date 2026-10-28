package com.tutict.finalassignmentcloud.ai.chat.context;

import com.tutict.finalassignmentcloud.ai.client.rag.RagRetrievalResult;
import com.tutict.finalassignmentcloud.ai.guardrail.PromptInjectionGuard;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class ContextBuilder {

    public static final String START_TAG = "<retrieved_context>";
    public static final String END_TAG = "</retrieved_context>";

    private final int contextTokenBudget;
    private final PromptInjectionGuard injectionGuard;

    @Autowired
    public ContextBuilder(
            @Value("${ai.prompt.context-token-budget:1200}") int contextTokenBudget,
            PromptInjectionGuard injectionGuard
    ) {
        this.contextTokenBudget = Math.max(0, contextTokenBudget);
        this.injectionGuard = injectionGuard == null ? new PromptInjectionGuard() : injectionGuard;
    }

    public ContextBuilder(int contextTokenBudget) {
        this(contextTokenBudget, new PromptInjectionGuard());
    }

    public String build(List<RagRetrievalResult> results) {
        return build(results, contextTokenBudget);
    }

    String build(List<RagRetrievalResult> results, int tokenBudget) {
        String body = contextBody(results, Math.max(0, tokenBudget));
        if (body.isBlank()) {
            return START_TAG + "\n" + END_TAG;
        }
        return START_TAG + "\n" + body + "\n" + END_TAG;
    }

    private String contextBody(List<RagRetrievalResult> results, int tokenBudget) {
        if (results == null || results.isEmpty() || tokenBudget == 0) {
            return "";
        }

        StringBuilder body = new StringBuilder();
        int remainingTokens = tokenBudget;
        int index = 1;
        for (RagRetrievalResult result : results) {
            String entry = entry(index, result);
            int entryTokens = estimateTokens(entry);
            if (entryTokens <= remainingTokens) {
                appendEntry(body, entry);
                remainingTokens -= entryTokens;
                index++;
                continue;
            }

            String truncated = truncateToTokenBudget(entry, remainingTokens);
            if (!truncated.isBlank()) {
                appendEntry(body, truncated);
            }
            break;
        }
        return body.toString();
    }

    private String entry(int index, RagRetrievalResult result) {
        // Retrieved context is untrusted: neutralize instruction-like spans before they
        // reach the model, so a poisoned document cannot hijack the prompt. Titles,
        // sources, and scores stay out of the prompt so the model cannot echo internal
        // identifiers into the answer; only the citation index and content are needed.
        return "[" + index + "]\n"
                + "content: " + injectionGuard.sanitize(normalizeWhitespace(result.content()));
    }

    private static void appendEntry(StringBuilder body, String entry) {
        if (!body.isEmpty()) {
            body.append("\n\n");
        }
        body.append(entry.strip());
    }

    static int estimateTokens(String text) {
        if (text == null || text.isBlank()) {
            return 0;
        }
        int tokens = 0;
        int index = 0;
        while (index < text.length()) {
            int codePoint = text.codePointAt(index);
            if (Character.isWhitespace(codePoint)) {
                index += Character.charCount(codePoint);
                continue;
            }
            tokens++;
            if (isAsciiLetterOrDigit(codePoint)) {
                index += Character.charCount(codePoint);
                while (index < text.length()) {
                    int next = text.codePointAt(index);
                    if (!isAsciiLetterOrDigit(next)) {
                        break;
                    }
                    index += Character.charCount(next);
                }
                continue;
            }
            index += Character.charCount(codePoint);
        }
        return tokens;
    }

    private static String truncateToTokenBudget(String text, int tokenBudget) {
        if (text == null || tokenBudget <= 0) {
            return "";
        }
        StringBuilder truncated = new StringBuilder();
        int tokens = 0;
        int index = 0;
        boolean previousWasWhitespace = false;
        while (index < text.length() && tokens < tokenBudget) {
            int codePoint = text.codePointAt(index);
            if (Character.isWhitespace(codePoint)) {
                if (!truncated.isEmpty() && !previousWasWhitespace) {
                    truncated.append(' ');
                    previousWasWhitespace = true;
                }
                index += Character.charCount(codePoint);
                continue;
            }

            if (isAsciiLetterOrDigit(codePoint)) {
                int start = index;
                index += Character.charCount(codePoint);
                while (index < text.length()) {
                    int next = text.codePointAt(index);
                    if (!isAsciiLetterOrDigit(next)) {
                        break;
                    }
                    index += Character.charCount(next);
                }
                truncated.append(text, start, index);
            } else {
                truncated.appendCodePoint(codePoint);
                index += Character.charCount(codePoint);
            }
            tokens++;
            previousWasWhitespace = false;
        }
        return truncated.toString().strip();
    }

    private static boolean isAsciiLetterOrDigit(int codePoint) {
        return codePoint >= '0' && codePoint <= '9'
                || codePoint >= 'A' && codePoint <= 'Z'
                || codePoint >= 'a' && codePoint <= 'z';
    }

    private static String normalizeWhitespace(String value) {
        return clean(value).replaceAll("[\\p{Zs}\\t\\r\\n]+", " ");
    }

    private static String clean(String value) {
        return value == null ? "" : value.trim();
    }
}
