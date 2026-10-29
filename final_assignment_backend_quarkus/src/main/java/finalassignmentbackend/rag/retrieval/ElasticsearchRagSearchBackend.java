package finalassignmentbackend.rag.retrieval;

import finalassignmentbackend.rag.access.RagAccessContext;
import finalassignmentbackend.rag.access.RagAclPolicy;
import finalassignmentbackend.rag.elasticsearch.ElasticsearchClient;
import finalassignmentbackend.rag.elasticsearch.ElasticsearchException;
import finalassignmentbackend.rag.elasticsearch.RagIndexManager;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObject;
import jakarta.json.JsonString;
import jakarta.json.JsonValue;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Elasticsearch 检索后端。
 *
 * <p>查询形态与 Spring 参考实现保持一致：BM25 用 multi_match 加短语加权，向量用顶层 knn，
 * 两侧都带上同一套 ACL 过滤，只负责减少候选量，最终可见性由 MySQL 侧的严格判定兜底。
 */
@ApplicationScoped
public class ElasticsearchRagSearchBackend implements RagSearchBackend {

    private final ElasticsearchClient client;
    private final RagIndexManager indexManager;

    @Inject
    public ElasticsearchRagSearchBackend(ElasticsearchClient client, RagIndexManager indexManager) {
        this.client = client;
        this.indexManager = indexManager;
    }

    @Override
    public List<RagSearchHit> bm25Search(String query, RagAccessContext context, int limit) {
        JsonArrayBuilder should = Json.createArrayBuilder()
                .add(multiMatch(query))
                .add(matchPhrase("title", query, 2))
                .add(matchPhrase("content", query, 1.5));
        JsonObject body = Json.createObjectBuilder()
                .add("size", Math.max(1, limit))
                .add("_source", sourceFilter())
                .add("query", Json.createObjectBuilder()
                        .add("bool", Json.createObjectBuilder()
                                .add("should", should)
                                .add("minimum_should_match", 1)
                                .add("filter", Json.createArrayBuilder().add(aclFilter(context)))))
                .build();
        return search(body, true);
    }

    @Override
    public List<RagSearchHit> vectorSearch(float[] queryVector, RagAccessContext context, int limit) {
        int size = Math.max(1, limit);
        JsonArrayBuilder vector = Json.createArrayBuilder();
        if (queryVector != null) {
            for (float value : queryVector) {
                vector.add((double) value);
            }
        }
        JsonObject body = Json.createObjectBuilder()
                .add("size", size)
                .add("_source", sourceFilter())
                .add("knn", Json.createObjectBuilder()
                        .add("field", "embedding")
                        .add("query_vector", vector)
                        .add("k", size)
                        .add("num_candidates", Math.max(50, size * 4))
                        .add("filter", aclFilter(context)))
                .build();
        return search(body, false);
    }

    private List<RagSearchHit> search(JsonObject body, boolean bm25) {
        try {
            return execute(indexManager.aliasName(), body, bm25);
        } catch (ElasticsearchException error) {
            String index = indexManager.indexName();
            if (index == null || index.equals(indexManager.aliasName())) {
                throw error;
            }
            return execute(index, body, bm25);
        }
    }

    private List<RagSearchHit> execute(String index, JsonObject body, boolean bm25) {
        JsonObject response = client.postJson("/" + index + "/_search", body);
        JsonObject hits = response.getJsonObject("hits");
        if (hits == null) {
            return List.of();
        }
        JsonArray array = hits.getJsonArray("hits");
        List<RagSearchHit> results = new ArrayList<>();
        if (array == null) {
            return results;
        }
        for (JsonValue item : array) {
            RagSearchHit hit = toHit(item, bm25);
            if (hit != null) {
                results.add(hit);
            }
        }
        return results;
    }

    private static RagSearchHit toHit(JsonValue item, boolean bm25) {
        if (item == null || item.getValueType() != JsonValue.ValueType.OBJECT) {
            return null;
        }
        JsonObject hit = item.asJsonObject();
        JsonObject source = hit.getJsonObject("_source");
        if (source == null) {
            return null;
        }
        String chunkId = text(source, "chunk_id");
        if (chunkId.isBlank()) {
            return null;
        }
        double score = hit.getJsonNumber("_score") == null ? 0 : hit.getJsonNumber("_score").doubleValue();
        RagAclPolicy.DocumentAcl acl = new RagAclPolicy.DocumentAcl(
                text(source, "acl_scope"),
                values(source, "acl_roles"),
                values(source, "acl_user_ids"),
                values(source, "acl_departments")
        );
        return new RagSearchHit(
                chunkId,
                text(source, "document_id"),
                text(source, "content"),
                text(source, "title"),
                text(source, "source_type"),
                text(source, "source_table"),
                text(source, "source_id"),
                text(source, "source_field"),
                text(source, "route"),
                bm25 ? score : 0,
                bm25 ? 0 : score,
                score,
                acl
        );
    }

    private static JsonObject multiMatch(String query) {
        return Json.createObjectBuilder()
                .add("multi_match", Json.createObjectBuilder()
                        .add("query", query == null ? "" : query)
                        .add("fields", Json.createArrayBuilder()
                                .add("title^4")
                                .add("content^3")
                                .add("source_field.text^1.5")
                                .add("source_type")
                                .add("source_table")))
                .build();
    }

    private static JsonObject matchPhrase(String field, String query, double boost) {
        return Json.createObjectBuilder()
                .add("match_phrase", Json.createObjectBuilder()
                        .add(field, Json.createObjectBuilder()
                                .add("query", query == null ? "" : query)
                                .add("boost", boost)))
                .build();
    }

    /** ACL 粗过滤：PUBLIC、命中角色、命中用户、命中部门，任一命中即可。 */
    private static JsonObject aclFilter(RagAccessContext context) {
        JsonArrayBuilder should = Json.createArrayBuilder().add(term("acl_scope", "PUBLIC"));
        if (context != null) {
            for (String role : context.roles()) {
                should.add(term("acl_roles", role));
            }
            if (context.userId() != null) {
                should.add(term("acl_user_ids", context.userId()));
            }
            if (context.department() != null) {
                should.add(term("acl_departments", context.department()));
            }
        }
        return Json.createObjectBuilder()
                .add("bool", Json.createObjectBuilder()
                        .add("should", should)
                        .add("minimum_should_match", 1))
                .build();
    }

    private static JsonObject term(String field, String value) {
        return Json.createObjectBuilder()
                .add("term", Json.createObjectBuilder().add(field, value))
                .build();
    }

    private static JsonObject sourceFilter() {
        return Json.createObjectBuilder()
                .add("excludes", Json.createArrayBuilder().add("embedding"))
                .build();
    }

    private static String text(JsonObject source, String field) {
        JsonValue value = source.get(field);
        if (value == null || value.getValueType() == JsonValue.ValueType.NULL) {
            return "";
        }
        if (value.getValueType() == JsonValue.ValueType.STRING) {
            return ((JsonString) value).getString();
        }
        return value.toString();
    }

    private static Set<String> values(JsonObject source, String field) {
        JsonValue value = source.get(field);
        if (value == null || value.getValueType() != JsonValue.ValueType.ARRAY) {
            return Set.of();
        }
        LinkedHashSet<String> collected = new LinkedHashSet<>();
        value.asJsonArray().forEach(item -> {
            if (item.getValueType() == JsonValue.ValueType.STRING) {
                String text = ((JsonString) item).getString();
                if (!text.isBlank()) {
                    collected.add(text);
                }
            }
        });
        return Collections.unmodifiableSet(collected);
    }
}
