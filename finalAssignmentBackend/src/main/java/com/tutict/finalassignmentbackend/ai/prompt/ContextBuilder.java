package com.tutict.finalassignmentbackend.ai.prompt;

import com.tutict.finalassignmentbackend.ai.guardrail.PromptInjectionGuard;
import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ContextBuilder {

    static final String START_TAG = "<retrieved_context>";
    static final String END_TAG = "</retrieved_context>";

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

    public String build(List<RetrievalResult> results) {
        return buildWithSources(results).context();
    }

    public record BuiltContext(String context, List<RetrievalResult> sources) {
    }

    public BuiltContext buildWithSources(List<RetrievalResult> results) {
        return buildWithSources(results, contextTokenBudget);
    }

    String build(List<RetrievalResult> results, int tokenBudget) {
        return buildWithSources(results, tokenBudget).context();
    }

    BuiltContext buildWithSources(List<RetrievalResult> results, int tokenBudget) {
        List<RetrievalResult> included = new java.util.ArrayList<>();
        String body = contextBody(results, Math.max(0, tokenBudget), included);
        if (body.isBlank()) {
            return new BuiltContext(START_TAG + "\n" + END_TAG, List.of());
        }
        return new BuiltContext(START_TAG + "\n" + body + "\n" + END_TAG, List.copyOf(included));
    }

    private String contextBody(List<RetrievalResult> results, int tokenBudget) {
        return contextBody(results, tokenBudget, null);
    }

    private String contextBody(
            List<RetrievalResult> results,
            int tokenBudget,
            List<RetrievalResult> included
    ) {
        if (results == null || results.isEmpty() || tokenBudget == 0) {
            return "";
        }

        StringBuilder body = new StringBuilder();
        int remainingTokens = tokenBudget;
        int index = 1;
        for (RetrievalResult result : results) {
            String entry = entry(index, result);
            int entryTokens = estimateTokens(entry);
            if (entryTokens <= remainingTokens) {
                appendEntry(body, entry);
                if (included != null) {
                    included.add(withContent(result, contentFromEntry(entry)));
                }
                remainingTokens -= entryTokens;
                index++;
                continue;
            }

            String truncated = truncateToTokenBudget(entry, remainingTokens);
            if (!truncated.isBlank()) {
                appendEntry(body, truncated);
                if (included != null) {
                    included.add(withContent(result, contentFromEntry(truncated)));
                }
            }
            break;
        }
        return body.toString();
    }

    private static String contentFromEntry(String entry) {
        int marker = entry.indexOf("content: ");
        return marker < 0 ? entry : entry.substring(marker + "content: ".length()).strip();
    }

    private static RetrievalResult withContent(RetrievalResult result, String content) {
        return new RetrievalResult(
                result.chunkId(), result.documentId(), content, result.title(), result.sourceType(),
                result.sourceTable(), result.sourceId(), result.sourceField(), result.route(),
                result.bm25Score(), result.vectorScore(), result.finalScore(), result.metadata());
    }

    private String entry(int index, RetrievalResult result) {
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
