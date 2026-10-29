package finalassignmentbackend.rag.retrieval;

import finalassignmentbackend.rag.access.RagAccessContext;
import finalassignmentbackend.rag.access.RagAclPolicy;
import finalassignmentbackend.rag.config.RagProperties;
import finalassignmentbackend.rag.embedding.RagEmbeddingProvider;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.text.Normalizer;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 混合检索：BM25 与向量各取一批候选，用 RRF 融合后再做一次词法加权。
 *
 * <p>公式与顺序对齐 Spring 参考实现：{@code 100 * weight / (rankConstant + rank)}，
 * 融合分低于阈值或可见性不通过的结果会被丢弃。
 */
@ApplicationScoped
public class HybridRetriever {

    private static final Logger LOG = Logger.getLogger(HybridRetriever.class.getName());
    private static final Pattern TOKEN_PATTERN = Pattern.compile("[\\p{IsHan}]{2,}|[\\p{Alnum}_]{2,}");

    private final RagEmbeddingProvider provider;
    private final RagSearchBackend backend;
    private final RagProperties properties;

    @Inject
    public HybridRetriever(RagEmbeddingProvider provider, RagSearchBackend backend, RagProperties properties) {
        this.provider = provider;
        this.backend = backend;
        this.properties = properties;
    }

    /**
     * 检索候选。
     *
     * @param limit 返回的候选上限，融合前会按倍数放大
     */
    public List<RagSearchHit> retrieve(String query, RagAccessContext context, int limit) {
        int candidateLimit = Math.max(limit, limit * Math.max(1, properties.getCandidateMultiplier()));
        List<RagSearchHit> bm25 = backend.bm25Search(query, context, candidateLimit);
        List<RagSearchHit> vector = vectorHits(query, context, candidateLimit);
        return rerank(query, fuse(bm25, vector, context), candidateLimit);
    }

    /** 向量侧不可用时退化为纯 BM25，词法召回不受影响。 */
    private List<RagSearchHit> vectorHits(String query, RagAccessContext context, int limit) {
        if (!properties.isEmbeddingEnabled()) {
            return List.of();
        }
        try {
            float[] vector = provider.embed(query);
            return backend.vectorSearch(vector, context, limit);
        } catch (RuntimeException error) {
            LOG.log(Level.WARNING, "Vector retrieval failed; continuing with BM25 only", error);
            return List.of();
        }
    }

    /** RRF 融合：同一分块在两侧都命中时累加排名分。 */
    public List<RagSearchHit> fuse(
            List<RagSearchHit> bm25,
            List<RagSearchHit> vector,
            RagAccessContext context
    ) {
        Map<String, ScoreAccumulator> byChunkId = new LinkedHashMap<>();
        accumulate(byChunkId, bm25, true);
        accumulate(byChunkId, vector, false);
        return byChunkId.values().stream()
                .map(accumulator -> accumulator.hit.withScores(
                        accumulator.bm25Score,
                        accumulator.vectorScore,
                        accumulator.rrfScore))
                .filter(hit -> hit.finalScore() >= properties.getMinScore())
                .filter(hit -> RagAclPolicy.allows(hit.acl(), context))
                .sorted(Comparator.comparingDouble(RagSearchHit::finalScore).reversed())
                .toList();
    }

    private void accumulate(
            Map<String, ScoreAccumulator> byChunkId,
            List<RagSearchHit> hits,
            boolean bm25
    ) {
        if (hits == null) {
            return;
        }
        for (int index = 0; index < hits.size(); index++) {
            RagSearchHit hit = hits.get(index);
            if (hit.chunkId() == null || hit.chunkId().isBlank()) {
                continue;
            }
            ScoreAccumulator accumulator = byChunkId.computeIfAbsent(
                    hit.chunkId(),
                    ignored -> new ScoreAccumulator(hit)
            );
            if (bm25) {
                accumulator.bm25Score = Math.max(accumulator.bm25Score, hit.bm25Score());
                accumulator.rrfScore += reciprocalRankScore(index + 1, properties.getBm25Weight());
            } else {
                accumulator.vectorScore = Math.max(accumulator.vectorScore, hit.vectorScore());
                accumulator.rrfScore += reciprocalRankScore(index + 1, properties.getVectorWeight());
            }
        }
    }

    private double reciprocalRankScore(int rank, double weight) {
        int rankConstant = Math.max(1, properties.getRrfRankConstant());
        return 100.0 * Math.max(0, weight) / (rankConstant + Math.max(1, rank));
    }

    /** 词法加权：标题与正文与查询的重合度给融合分加一点权重。 */
    List<RagSearchHit> rerank(String query, List<RagSearchHit> hits, int limit) {
        List<RagSearchHit> ranked = hits;
        if (properties.isRerankEnabled() && hits.size() >= 2) {
            Set<String> queryTokens = tokens(query);
            double weight = clamp(properties.getRerankLexicalWeight());
            if (!queryTokens.isEmpty() && weight > 0) {
                ranked = hits.stream()
                        .map(hit -> hit.withScores(hit.bm25Score(), hit.vectorScore(),
                                hit.finalScore() + lexicalScore(queryTokens, hit) * weight))
                        .sorted(Comparator.comparingDouble(RagSearchHit::finalScore).reversed())
                        .toList();
            }
        }
        return ranked.stream().limit(Math.max(1, limit)).toList();
    }

    private static double lexicalScore(Set<String> queryTokens, RagSearchHit hit) {
        double titleScore = overlap(queryTokens, hit.title());
        double contentScore = overlap(queryTokens, hit.content());
        double sourceScore = overlap(queryTokens, hit.sourceField());
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

    static Set<String> tokens(String text) {
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

    private static final class ScoreAccumulator {

        private final RagSearchHit hit;
        private double bm25Score;
        private double vectorScore;
        private double rrfScore;

        private ScoreAccumulator(RagSearchHit hit) {
            this.hit = hit;
            this.bm25Score = hit.bm25Score();
            this.vectorScore = hit.vectorScore();
        }
    }
}
