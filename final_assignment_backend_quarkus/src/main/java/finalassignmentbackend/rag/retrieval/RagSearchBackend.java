package finalassignmentbackend.rag.retrieval;

import finalassignmentbackend.rag.access.RagAccessContext;

import java.util.List;

/**
 * 检索后端。
 *
 * <p>把 Elasticsearch 隔在接口后面，融合逻辑因此可以脱离真实集群做单元测试。
 */
public interface RagSearchBackend {

    /** 词法检索。 */
    List<RagSearchHit> bm25Search(String query, RagAccessContext context, int limit);

    /** 向量检索。 */
    List<RagSearchHit> vectorSearch(float[] queryVector, RagAccessContext context, int limit);
}
