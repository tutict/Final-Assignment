package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import java.text.Normalizer;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 评测用分词器：与生产 {@code LightweightRerankProvider} 的分词规则保持一致
 * （CJK 连续串切 2-gram，拉丁/数字串按词切分），保证离线评测与线上 rerank 行为同源。
 */
final class EvalTokenizer {

    private static final Pattern TOKEN_PATTERN = Pattern.compile("[\\p{IsHan}]{2,}|[\\p{Alnum}_]{2,}");

    private EvalTokenizer() {
    }

    static List<String> tokens(String text) {
        if (text == null || text.isBlank()) {
            return List.of();
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
        return List.copyOf(tokens);
    }

    private static boolean hasCjk(String value) {
        return value.codePoints().anyMatch(codePoint -> Character.UnicodeScript.of(codePoint)
                == Character.UnicodeScript.HAN);
    }
}