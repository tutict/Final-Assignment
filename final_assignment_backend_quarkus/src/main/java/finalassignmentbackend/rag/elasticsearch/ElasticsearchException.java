package finalassignmentbackend.rag.elasticsearch;

/**
 * Elasticsearch 调用失败。保留状态码与截断后的响应体，便于运维定位索引/映射问题。
 */
public class ElasticsearchException extends RuntimeException {

    private static final int BODY_LIMIT = 500;

    private final int status;

    public ElasticsearchException(String message) {
        this(message, 0, "");
    }

    public ElasticsearchException(String message, Throwable cause) {
        super(message, cause);
        this.status = 0;
    }

    public ElasticsearchException(String message, int status, String body) {
        super(message + " (status=" + status + (body.isBlank() ? "" : ", body=" + clip(body)) + ")");
        this.status = status;
    }

    public int status() {
        return status;
    }

    public static String clip(String body) {
        if (body == null) {
            return "";
        }
        String normalized = body.replaceAll("\\s+", " ").trim();
        return normalized.length() <= BODY_LIMIT ? normalized : normalized.substring(0, BODY_LIMIT) + "...";
    }
}
