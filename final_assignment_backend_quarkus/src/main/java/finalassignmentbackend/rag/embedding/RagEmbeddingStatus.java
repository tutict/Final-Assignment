package finalassignmentbackend.rag.embedding;

/**
 * 嵌入任务与分块的状态常量。
 *
 * <p>{@code rag_embedding_task} 表由 Spring / Go / Quarkus 三个后端共用，状态取值必须保持一致。
 */
public final class RagEmbeddingStatus {

    public static final String PENDING = "PENDING";
    public static final String RUNNING = "RUNNING";
    public static final String SUCCEEDED = "SUCCEEDED";
    public static final String FAILED = "FAILED";
    public static final String POISONED = "POISONED";

    /** 分块已写入 ES。 */
    public static final String CHUNK_EMBEDDED = "EMBEDDED";
    /** 分块已排队等待嵌入。 */
    public static final String CHUNK_PENDING_EMBEDDING = "PENDING_EMBEDDING";

    private RagEmbeddingStatus() {
    }
}
