package com.tutict.finalassignmentbackend.ai.prompt;

import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class ContextBuilder {

    static final String START_TAG = "<retrieved_context>";
    static final String END_TAG = "</retrieved_context>";

    private final int contextTokenBudget;

    public ContextBuilder(@Value("${ai.prompt.context-token-budget:1200}") int contextTokenBudget) {
        this.contextTokenBudget = Math.max(0, contextTokenBudget);
    }

    public String build(List<RetrievalResult> results) {
        return build(results, contextTokenBudget);
    }

    String build(List<RetrievalResult> results, int tokenBudget) {
        String body = contextBody(results, Math.max(0, tokenBudget));
        if (body.isBlank()) {
            return START_TAG + "\n" + END_TAG;
        }
        return START_TAG + "\n" + body + "\n" + END_TAG;
    }

    private static String contextBody(List<RetrievalResult> results, int tokenBudget) {
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

    private static String entry(int index, RetrievalResult result) {
        return "[" + index + "]\n"
                + "title: " + clean(result.title()) + "\n"
                + "source: " + source(result) + "\n"
                + "score: " + score(result.finalScore()) + "\n"
                + "content: " + normalizeWhitespace(result.content());
    }

    private static String source(RetrievalResult result) {
        String explicit = metadataString(result.metadata(), "source", "citationSource");
        if (!explicit.isBlank()) {
            return explicit;
        }
        String sourceTable = clean(result.sourceTable());
        String sourceId = clean(result.sourceId());
        if (!sourceTable.isBlank() && !sourceId.isBlank()) {
            return sourceTable + ":" + sourceId;
        }
        if (!sourceTable.isBlank()) {
            return sourceTable;
        }
        String documentId = clean(result.documentId());
        if (!documentId.isBlank()) {
            return documentId;
        }
        return clean(result.chunkId());
    }

    private static String metadataString(Map<String, Object> metadata, String... keys) {
        for (String key : keys) {
            Object value = metadata.get(key);
            if (value != null && !value.toString().isBlank()) {
                return value.toString().trim();
            }
        }
        return "";
    }

    private static String score(double score) {
        return String.format(Locale.ROOT, "%.4f", score);
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
