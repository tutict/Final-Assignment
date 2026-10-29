package finalassignmentbackend.rag.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.RagChunkMapper;
import finalassignmentbackend.mapper.RagDocumentMapper;
import finalassignmentbackend.rag.access.RagAccessContext;
import finalassignmentbackend.rag.access.RagAclPolicy;
import finalassignmentbackend.rag.config.RagProperties;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import finalassignmentbackend.rag.retrieval.HybridRetriever;
import finalassignmentbackend.rag.retrieval.RagSearchHit;
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
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * 知识库检索。
 *
 * <p>优先走 Elasticsearch 的混合检索（BM25 + 向量），命中后回 MySQL 做严格可见性判定；
 * 只有 ES 调用本身失败时才回退到 MySQL 词法检索——ES 正常返回空结果不回退，否则会用词法
 * 命中掩盖向量检索的缺陷。
 */
@ApplicationScoped
public class RagQueryService {

    private static final Logger LOG = Logger.getLogger(RagQueryService.class.getName());

    public static final int DEFAULT_TOP_K = 5;
    public static final int MAX_TOP_K = 50;

    @Inject HybridRetriever hybridRetriever;
    @Inject MySqlRagCandidateStore candidateStore;
    @Inject RagDocumentMapper documentMapper;
    @Inject RagChunkMapper chunkMapper;
    @Inject RagProperties properties;

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

    public List<RetrievedChunk> retrieve(String query, RagAccessContext context, int topK) {
        String needle = query == null ? "" : query.trim();
        if (needle.isBlank()) {
            return List.of();
        }
        int limit = Math.max(1, Math.min(topK, MAX_TOP_K));
        if (properties.isEnabled() && properties.isRetrievalEnabled() && properties.isElasticsearchEnabled()) {
            try {
                return hybridRetrieve(needle, context, limit);
            } catch (RuntimeException error) {
                if (!properties.isMysqlFallbackEnabled()) {
                    throw error;
                }
                LOG.log(Level.WARNING, "Elasticsearch retrieval failed; falling back to MySQL lexical search", error);
            }
        }
        return lexicalRetrieve(needle, context, limit);
    }

    /** ES 混合检索：融合后的候选回到库里做严格判定，再截断到 topK。 */
    private List<RetrievedChunk> hybridRetrieve(String query, RagAccessContext context, int limit) {
        List<RagSearchHit> hits = hybridRetriever.retrieve(query, context, limit);
        List<MySqlRagCandidateStore.Candidate> candidates = candidateStore.resolve(hits, context);
        List<RetrievedChunk> results = new ArrayList<>();
        for (MySqlRagCandidateStore.Candidate candidate : candidates) {
            results.add(new RetrievedChunk(
                    candidate.chunkId(),
                    candidate.documentId(),
                    candidate.sourceId(),
                    candidate.content(),
                    candidate.title(),
                    candidate.sourceType(),
                    candidate.route(),
                    candidate.finalScore()
            ));
        }
        return results.size() > limit ? List.copyOf(results.subList(0, limit)) : List.copyOf(results);
    }

    /** ES 不可用时的词法回退：整句命中加中文二元组，判定规则与 ES 路径一致。 */
    private List<RetrievedChunk> lexicalRetrieve(String query, RagAccessContext context, int limit) {
        List<RagDocument> allowed = allowedDocuments(context);
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
            double score = score(query, document.getTitle(), chunk.getContent());
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

    /** 可被检索到的知识文档：来源类型受限，且必须通过可见性判定。 */
    List<RagDocument> allowedDocuments(RagAccessContext context) {
        List<RagDocument> docs = documentMapper.selectList(
                new QueryWrapper<RagDocument>().in("source_type", List.of("MANUAL", "UPLOAD"))
        );
        return selectAllowedDocuments(docs, context);
    }

    static List<RagDocument> selectAllowedDocuments(List<RagDocument> docs, RagAccessContext context) {
        List<RagDocument> allowed = new ArrayList<>();
        if (docs == null) {
            return allowed;
        }
        for (RagDocument document : docs) {
            if (RagAdminDocumentSupport.isKnowledgeDocument(document)
                    && RagAclPolicy.allows(RagAclPolicy.parse(document), context)) {
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

    /**
     * 词法打分。
     *
     * <p>中文问题很少逐字复述原文，整句不命中时用二元组兜底，但权重刻意压低，
     * 避免几个共字压过整句命中。
     */
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
