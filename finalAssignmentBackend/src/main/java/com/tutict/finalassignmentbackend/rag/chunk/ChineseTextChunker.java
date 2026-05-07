package com.tutict.finalassignmentbackend.rag.chunk;

import com.tutict.finalassignmentbackend.rag.config.RagProperties;
import com.tutict.finalassignmentbackend.rag.dto.RagSourceDocument;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;

@Component
public class ChineseTextChunker implements Chunker {

    private final int chunkSize;
    private final int overlap;

    public ChineseTextChunker(RagProperties properties) {
        this(properties.getChunk().getSize(), properties.getChunk().getOverlap());
    }

    public ChineseTextChunker(int chunkSize, int overlap) {
        this.chunkSize = Math.max(1, chunkSize);
        this.overlap = Math.max(0, Math.min(overlap, this.chunkSize - 1));
    }

    @Override
    public List<Chunk> chunk(RagSourceDocument document) {
        String normalized = normalizeContent(document.content());
        if (normalized.isBlank()) {
            return List.of();
        }

        int[] codePoints = normalized.codePoints().toArray();
        List<Chunk> chunks = new ArrayList<>();
        int start = 0;
        int chunkNo = 0;
        while (start < codePoints.length) {
            int end = Math.min(start + chunkSize, codePoints.length);
            String content = new String(codePoints, start, end - start);
            chunks.add(new Chunk(
                    chunkNo++,
                    content,
                    normalizedContentSha256(content),
                    estimateTokenCount(content),
                    content.codePointCount(0, content.length()),
                    document.sourceField()
            ));
            if (end == codePoints.length) {
                break;
            }
            start = Math.max(start + 1, end - overlap);
        }
        return chunks;
    }

    @Override
    public String normalizedContentSha256(String content) {
        return normalizedContentSha256Of(content);
    }

    public static String normalizedContentSha256Of(String content) {
        return sha256Hex(normalizeContent(content));
    }

    public static String normalizeContent(String content) {
        if (content == null) {
            return "";
        }
        return Normalizer.normalize(content, Normalizer.Form.NFKC)
                .replace("\r\n", "\n")
                .replace('\r', '\n')
                .replace('\u000B', ' ')
                .replaceAll("[\\p{Zs}\\t\\f]+", " ")
                .replaceAll(" *\\n *", "\n")
                .replaceAll("\\n{3,}", "\n\n")
                .trim();
    }

    private static String sha256Hex(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA-256 is not available", error);
        }
    }

    private static int estimateTokenCount(String value) {
        int count = 0;
        boolean inAsciiWord = false;
        for (int i = 0; i < value.length(); ) {
            int codePoint = value.codePointAt(i);
            i += Character.charCount(codePoint);
            if (Character.isWhitespace(codePoint)) {
                inAsciiWord = false;
            } else if (isAsciiLetterOrDigit(codePoint)) {
                if (!inAsciiWord) {
                    count++;
                }
                inAsciiWord = true;
            } else {
                count++;
                inAsciiWord = false;
            }
        }
        return count;
    }

    private static boolean isAsciiLetterOrDigit(int codePoint) {
        return codePoint >= '0' && codePoint <= '9'
                || codePoint >= 'A' && codePoint <= 'Z'
                || codePoint >= 'a' && codePoint <= 'z';
    }
}
