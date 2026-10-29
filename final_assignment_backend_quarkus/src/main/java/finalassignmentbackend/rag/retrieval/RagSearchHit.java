package finalassignmentbackend.rag.retrieval;

import finalassignmentbackend.rag.access.RagAclPolicy;

/**
 * 一条检索命中。
 *
 * <p>既承载 ES 返回的正文与分数，也承载判定可见性所需的 ACL 信息。
 */
public record RagSearchHit(
        String chunkId,
        String documentId,
        String content,
        String title,
        String sourceType,
        String sourceTable,
        String sourceId,
        String sourceField,
        String route,
        double bm25Score,
        double vectorScore,
        double finalScore,
        RagAclPolicy.DocumentAcl acl
) {

    public RagSearchHit withScores(double bm25, double vector, double finalScore) {
        return new RagSearchHit(chunkId, documentId, content, title, sourceType, sourceTable, sourceId,
                sourceField, route, bm25, vector, finalScore, acl);
    }
}
