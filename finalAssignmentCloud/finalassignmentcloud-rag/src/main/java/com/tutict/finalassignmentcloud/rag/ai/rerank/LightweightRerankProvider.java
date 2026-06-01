package com.tutict.finalassignmentcloud.rag.ai.rerank;

import com.tutict.finalassignmentcloud.rag.ai.config.RagRetrievalProperties;
import com.tutict.finalassignmentcloud.rag.ai.dto.RetrievalResult;
import org.springframework.stereotype.Component;

import java.text.Normalizer;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class LightweightRerankProvider implements RerankProvider {

    private static final Pattern TOKEN_PATTERN = Pattern.compile("[\\p{IsHan}]{2,}|[\\p{Alnum}_]{2,}");

    private final RagRetrievalProperties properties;

    public LightweightRerankProvider(RagRetrievalProperties properties) {
        this.properties = properties;
    }

    @Override
    public List<RetrievalResult> rerank(String query, List<RetrievalResult> results) {
        if (!properties.isRerankEnabled() || results.size() < 2) {
            return results;
        }
        Set<String> queryTokens = tokens(query);
        if (queryTokens.isEmpty()) {
            return results;
        }
        double weight = clamp(properties.getRerankLexicalWeight());
        if (weight <= 0) {
            return results;
        }

        return results.stream()
                .map(result -> result.withScores(
                        result.bm25Score(),
                        result.vectorScore(),
                        result.finalScore() + lexicalScore(queryTokens, result) * weight
                ))
                .sorted(Comparator.comparingDouble(RetrievalResult::finalScore).reversed())
                .toList();
    }

    private static double lexicalScore(Set<String> queryTokens, RetrievalResult result) {
        double titleScore = overlap(queryTokens, result.title());
        double contentScore = overlap(queryTokens, result.content());
        double sourceScore = overlap(queryTokens, result.sourceField());
        return titleScore * 0.45 + contentScore * 0.45 + sourceScore * 0.10;
    }

    private static double overlap(Set<String> queryTokens, String text) {
        Set<String> textTokens = tokens(text);
        if (textTokens.isEmpty()) {
            return 0;
        }
        long hits = queryTokens.stream().filter(textTokens::contains).count();
        return (double) hits / queryTokens.size();
    }

    private static Set<String> tokens(String text) {
        if (text == null || text.isBlank()) {
            return Set.of();
        }
        String normalized = Normalizer.normalize(text, Normalizer.Form.NFKC).toLowerCase(Locale.ROOT);
        Set<String> tokens = new LinkedHashSet<>();
        Matcher matcher = TOKEN_PATTERN.matcher(normalized);
        while (matcher.find()) {
            String token = matcher.group();
            tokens.add(token);
            if (hasCjk(token) && token.length() > 2) {
                for (int index = 0; index <= token.length() - 2; index++) {
                    tokens.add(token.substring(index, index + 2));
                }
            }
        }
        return tokens;
    }

    private static boolean hasCjk(String value) {
        return value.codePoints().anyMatch(codePoint -> Character.UnicodeScript.of(codePoint)
                == Character.UnicodeScript.HAN);
    }

    private static double clamp(double value) {
        if (Double.isNaN(value) || value <= 0) {
            return 0;
        }
        return Math.min(1, value);
    }
}

