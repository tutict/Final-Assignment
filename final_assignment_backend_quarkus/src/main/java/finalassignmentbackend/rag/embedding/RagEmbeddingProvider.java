package finalassignmentbackend.rag.embedding;

/**
 * RAG 分块的向量提供方。
 *
 * <p>实现必须返回与索引映射一致的维度数，否则分块永远无法写入 ES。
 */
public interface RagEmbeddingProvider {

    String providerName();

    String modelName();

    int dimensions();

    float[] embed(String text);
}
