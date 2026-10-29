package finalassignmentbackend.rag.elasticsearch;

import finalassignmentbackend.rag.config.RagProperties;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import jakarta.json.JsonObjectBuilder;

/**
 * RAG 分块的 Elasticsearch 映射。
 *
 * <p>字段与 Spring 参考实现（{@code RagChunkIndexMapping}）保持一致，避免同一套评测语料在
 * 两个后端上落到不同字段上。
 */
@ApplicationScoped
public class RagIndexMapping {

    @Inject RagProperties properties;

    public JsonObject mapping() {
        String analyzer = analyzer();
        JsonObjectBuilder fields = Json.createObjectBuilder();
        fields.add("chunk_id", keyword());
        fields.add("document_id", keyword());
        fields.add("content", text(analyzer));
        fields.add("title", textWithKeyword(analyzer));
        fields.add("source_type", keyword());
        fields.add("source_table", keyword());
        fields.add("source_id", keyword());
        fields.add("source_field", keywordWithText(analyzer));
        fields.add("source_version", keyword());
        fields.add("route", keyword());
        fields.add("acl_scope", keyword());
        fields.add("acl_roles", keyword());
        fields.add("acl_user_ids", keyword());
        fields.add("acl_departments", keyword());
        fields.add("embedding_provider", keyword());
        fields.add("embedding_model", keyword());
        fields.add("metadata", Json.createObjectBuilder()
                .add("type", "object")
                .add("enabled", true)
                .build());
        fields.add("embedding", Json.createObjectBuilder()
                .add("type", "dense_vector")
                .add("dims", dimensions())
                .add("index", true)
                .add("similarity", "cosine")
                .build());
        return Json.createObjectBuilder().add("properties", fields.build()).build();
    }

    public JsonObject settings() {
        JsonObjectBuilder index = Json.createObjectBuilder()
                .add("number_of_shards", Math.max(1, properties.getIndexShards()))
                .add("number_of_replicas", Math.max(0, properties.getIndexReplicas()));
        String refreshInterval = properties.getIndexRefreshInterval();
        if (refreshInterval != null && !refreshInterval.isBlank()) {
            index.add("refresh_interval", refreshInterval.trim());
        }
        return Json.createObjectBuilder().add("index", index.build()).build();
    }

    /** 创建索引的请求体：settings + mappings。 */
    public JsonObject createBody() {
        return Json.createObjectBuilder()
                .add("settings", settings())
                .add("mappings", mapping())
                .build();
    }

    private String analyzer() {
        String analyzer = properties.getIndexTextAnalyzer();
        return analyzer == null || analyzer.isBlank() ? "standard" : analyzer.trim();
    }

    private int dimensions() {
        return Math.max(1, properties.getEmbeddingDimensions());
    }

    private static JsonObject keyword() {
        return Json.createObjectBuilder().add("type", "keyword").build();
    }

    private static JsonObject text(String analyzer) {
        return Json.createObjectBuilder()
                .add("type", "text")
                .add("analyzer", analyzer)
                .build();
    }

    private static JsonObject textWithKeyword(String analyzer) {
        return Json.createObjectBuilder()
                .add("type", "text")
                .add("analyzer", analyzer)
                .add("fields", Json.createObjectBuilder()
                        .add("keyword", Json.createObjectBuilder()
                                .add("type", "keyword")
                                .add("ignore_above", 256)
                                .build())
                        .build())
                .build();
    }

    private static JsonObject keywordWithText(String analyzer) {
        return Json.createObjectBuilder()
                .add("type", "keyword")
                .add("fields", Json.createObjectBuilder()
                        .add("text", text(analyzer))
                        .build())
                .build();
    }
}
