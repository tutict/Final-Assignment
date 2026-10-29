package finalassignmentbackend.rag.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.RagChunkMapper;
import finalassignmentbackend.mapper.RagDocumentMapper;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Keyword retrieval over the MySQL knowledge base.
 *
 * <p>Quarkus does not write Elasticsearch, so this service is the only retrieval source. The
 * score combines whole-query hits with Chinese bigram hits: without the bigram term a question
 * phrased differently from the stored passage ("罚款怎么缴" vs "罚款应在十五日内缴纳")
 * scores zero and retrieval looks empty even though the passage is there.
 */
@ApplicationScoped
public class RagQueryService {

    public static final int DEFAULT_TOP_K = 5;
    public static final int MAX_TOP_K = 20;

    @Inject RagDocumentMapper documentMapper;
    @Inject RagChunkMapper chunkMapper;

    public record RetrievedChunk(
            String chunkId,
            String documentId,
            String sourceId,
            String content,
            String title,
            String sourceType,
            String route,
            double finalScore
    ) {
    }

    public List<RetrievedChunk> retrieve(String query, String asRole, int topK) {
        String needle = query == null ? "" : query.trim();
        if (needle.isBlank()) {
            return List.of();
        }
        int limit = Math.max(1, Math.min(topK, MAX_TOP_K));
        List<RagDocument> allowed = allowedDocuments(asRole);
        if (allowed.isEmpty()) {
            return List.of();
        }
        Map<String, RagDocument> byId = new LinkedHashMap<>();
        List<String> ids = new ArrayList<>();
        for (RagDocument document : allowed) {
            byId.put(document.getId(), document);
            ids.add(document.getId());
        }
        List<RagChunk> chunks = chunkMapper.selectList(
                new QueryWrapper<RagChunk>().in("document_id", ids).orderByAsc("chunk_no")
        );
        List<RetrievedChunk> results = new ArrayList<>();
        for (RagChunk chunk : chunks) {
            RagDocument document = byId.get(chunk.getDocumentId());
            if (document == null) {
                continue;
            }
            double score = score(needle, document.getTitle(), chunk.getContent());
            if (score <= 0) {
                continue;
            }
            results.add(toResult(chunk, document, score));
        }
        results.sort(Comparator
                .comparingDouble(RetrievedChunk::finalScore).reversed()
                .thenComparing(RetrievedChunk::documentId)
                .thenComparing(RetrievedChunk::chunkId));
        if (results.size() > limit) {
            return List.copyOf(results.subList(0, limit));
        }
        return List.copyOf(results);
    }

    List<RagDocument> allowedDocuments(String asRole) {
        List<RagDocument> docs = documentMapper.selectList(
                new QueryWrapper<RagDocument>().in("source_type", List.of("MANUAL", "UPLOAD"))
        );
        return selectAllowedDocuments(docs, asRole);
    }

    static List<RagDocument> selectAllowedDocuments(List<RagDocument> docs, String asRole) {
        List<RagDocument> allowed = new ArrayList<>();
        if (docs == null) {
            return allowed;
        }
        for (RagDocument document : docs) {
            if (RagAdminDocumentSupport.isKnowledgeDocument(document)
                    && RagAdminDocumentSupport.previewAllows(asRole, document.getAclScope())) {
                allowed.add(document);
            }
        }
        return allowed;
    }

    static RetrievedChunk toResult(RagChunk chunk, RagDocument document, double score) {
        return new RetrievedChunk(
                chunk.getId(),
                document.getId(),
                document.getSourceId(),
                chunk.getContent(),
                document.getTitle(),
                document.getSourceType(),
                document.getRoute(),
                score
        );
    }

    static double score(String query, String title, String content) {
        String needle = query == null ? "" : query.trim().toLowerCase(Locale.ROOT);
        if (needle.isBlank()) {
            return 0;
        }
        String titleText = title == null ? "" : title.toLowerCase(Locale.ROOT);
        String body = content == null ? "" : content.toLowerCase(Locale.ROOT);
        double score = 0;
        if (titleText.contains(needle)) {
            score += 2.0;
        }
        int from = 0;
        int hits = 0;
        while (hits < 20) {
            int index = body.indexOf(needle, from);
            if (index < 0) {
                break;
            }
            hits++;
            from = index + needle.length();
        }
        score += Math.min(3.0, hits * 0.5);
        for (String token : needle.split("[\\s、，,。；;：:？?！!的了吗呢么]+")) {
            if (token.length() < 2) {
                continue;
            }
            if (titleText.contains(token)) {
                score += 0.8;
            }
            if (body.contains(token)) {
                score += 0.4;
            }
            score += bigramScore(token, titleText, body);
        }
        return score;
    }

    /**
     * Chinese questions rarely repeat the passage wording verbatim. Bigrams are deliberately
     * weak (0.35/0.15) so a couple of shared characters cannot outrank a whole-phrase match.
     */
    static double bigramScore(String token, String titleText, String body) {
        if (token.length() <= 2 || !containsHan(token)) {
            return 0;
        }
        Set<String> bigrams = new LinkedHashSet<>();
        for (int i = 0; i + 1 < token.length(); i++) {
            String bigram = token.substring(i, i + 2);
            if (containsHan(bigram)) {
                bigrams.add(bigram);
            }
        }
        if (bigrams.isEmpty()) {
            return 0;
        }
        int titleHits = 0;
        int bodyHits = 0;
        for (String bigram : bigrams) {
            if (titleText.contains(bigram)) {
                titleHits++;
            }
            if (body.contains(bigram)) {
                bodyHits++;
            }
        }
        return Math.min(1.4, titleHits * 0.35) + Math.min(1.2, bodyHits * 0.15);
    }

    static boolean containsHan(String text) {
        for (int i = 0; i < text.length(); i++) {
            if (Character.UnicodeScript.of(text.charAt(i)) == Character.UnicodeScript.HAN) {
                return true;
            }
        }
        return false;
    }
}
