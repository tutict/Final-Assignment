package finalassignmentbackend.rag.retrieval;

import finalassignmentbackend.rag.access.RagAccessContext;
import finalassignmentbackend.rag.elasticsearch.ElasticsearchClient;
import finalassignmentbackend.rag.elasticsearch.ElasticsearchException;
import finalassignmentbackend.rag.elasticsearch.RagIndexManager;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import jakarta.json.JsonValue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ElasticsearchRagSearchBackendTest {

    private RecordingClient client;
    private ElasticsearchRagSearchBackend backend;

    @BeforeEach
    void setUp() {
        client = new RecordingClient();
        backend = new ElasticsearchRagSearchBackend(client, new FixedIndexManager());
    }

    @Test
    void bm25QueryUsesMultiMatchPhraseBoostsAndAclFilter() {
        backend.bm25Search("罚款缴纳", RagAccessContext.of("driver-1", Set.of("USER")), 5);

        JsonObject body = client.lastBody;
        JsonObject bool = body.getJsonObject("query").getJsonObject("bool");
        assertEquals(5, body.getInt("size"));
        assertEquals(3, bool.getJsonArray("should").size());
        assertEquals(1, bool.getInt("minimum_should_match"));
        JsonObject acl = bool.getJsonArray("filter").getJsonObject(0).getJsonObject("bool");
        assertEquals(1, acl.getInt("minimum_should_match"));
        List<String> should = new ArrayList<>();
        acl.getJsonArray("should").forEach(item -> should.add(item.asJsonObject().toString()));
        assertTrue(should.stream().anyMatch(text -> text.contains("acl_scope") && text.contains("PUBLIC")));
        assertTrue(should.stream().anyMatch(text -> text.contains("acl_user_ids") && text.contains("driver-1")));
    }

    @Test
    void vectorQueryUsesKnnWithTheSameAclFilter() {
        backend.vectorSearch(new float[]{0.1f, 0.2f}, RagAccessContext.of("driver-1", Set.of("USER")), 4);

        JsonObject body = client.lastBody;
        JsonObject knn = body.getJsonObject("knn");
        assertEquals("embedding", knn.getString("field"));
        assertEquals(4, knn.getInt("k"));
        assertEquals(50, knn.getInt("num_candidates"));
        assertEquals(2, knn.getJsonArray("query_vector").size());
        assertTrue(knn.getJsonObject("filter").getJsonObject("bool").getJsonArray("should").size() >= 2);
    }

    @Test
    void hitsAreMappedToSearchHitsWithAclInformation() {
        JsonObject source = Json.createObjectBuilder()
                .add("chunk_id", "chunk-1")
                .add("document_id", "doc-1")
                .add("content", "罚款应当在十五日内缴纳。")
                .add("title", "缴款期限")
                .add("source_type", "MANUAL")
                .add("source_id", "seed-1")
                .add("acl_scope", "USER")
                .add("acl_user_ids", Json.createArrayBuilder().add("driver-1"))
                .build();
        JsonObject hit = Json.createObjectBuilder()
                .add("_score", 3.5)
                .add("_source", source)
                .build();
        client.response = Json.createObjectBuilder()
                .add("hits", Json.createObjectBuilder()
                        .add("hits", Json.createArrayBuilder().add(hit)))
                .build();

        List<RagSearchHit> hits = backend.bm25Search("罚款", RagAccessContext.of("driver-1", Set.of("USER")), 5);

        assertEquals(1, hits.size());
        RagSearchHit mapped = hits.get(0);
        assertEquals("chunk-1", mapped.chunkId());
        assertEquals("doc-1", mapped.documentId());
        assertEquals("seed-1", mapped.sourceId());
        assertEquals(3.5, mapped.bm25Score());
        assertEquals(0, mapped.vectorScore());
        assertEquals("USER", mapped.acl().scope());
        assertEquals(Set.of("driver-1"), mapped.acl().userIds());
    }

    @Test
    void missingAliasFallsBackToThePhysicalIndex() {
        client.failOnAlias = true;

        List<RagSearchHit> hits = backend.bm25Search("罚款", RagAccessContext.of("driver-1", Set.of("USER")), 5);

        assertTrue(hits.isEmpty());
        assertEquals(List.of("/rag_chunk_quarkus_current/_search", "/rag_chunk_quarkus_v1/_search"), client.paths);
    }

    @Test
    void searchFailurePropagatesSoTheCallerCanFallBack() {
        client.failure = new ElasticsearchException("Elasticsearch POST failed", 500, "boom");

        assertThrows(ElasticsearchException.class,
                () -> backend.bm25Search("罚款", RagAccessContext.of("driver-1", Set.of("USER")), 5));
    }

    private static final class RecordingClient extends ElasticsearchClient {

        private final List<String> paths = new ArrayList<>();
        private JsonObject response = Json.createObjectBuilder()
                .add("hits", Json.createObjectBuilder().add("hits", Json.createArrayBuilder()).build())
                .build();        private boolean failOnAlias;
        private ElasticsearchException failure;
        private JsonObject lastBody;

        @Override
        public JsonObject postJson(String path, JsonObject body) {
            paths.add(path);
            lastBody = body;
            if (failure != null) {
                throw failure;
            }
            if (failOnAlias && path.contains("current")) {
                throw new ElasticsearchException("Elasticsearch POST failed", 404, "no such alias");
            }
            return response;
        }
    }

    private static final class FixedIndexManager extends RagIndexManager {

        @Override
        public String indexName() {
            return "rag_chunk_quarkus_v1";
        }

        @Override
        public String aliasName() {
            return "rag_chunk_quarkus_current";
        }
    }
}
