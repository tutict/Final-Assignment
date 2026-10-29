package finalassignmentbackend.rag.embedding;

/**
 * 嵌入请求失败。
 *
 * <p>{@code status} 为 0 表示请求没有到达服务端（连接失败、超时、响应无法解析）。
 */
public class RagEmbeddingException extends RuntimeException {

    private final int status;

    public RagEmbeddingException(String message, int status) {
        super(message);
        this.status = status;
    }

    public RagEmbeddingException(String message, Throwable cause) {
        super(message, cause);
        this.status = 0;
    }

    public int status() {
        return status;
    }
}
