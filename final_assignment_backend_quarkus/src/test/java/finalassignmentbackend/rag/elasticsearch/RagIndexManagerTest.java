package finalassignmentbackend.rag.elasticsearch;

import finalassignmentbackend.rag.config.RagProperties;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RagIndexManagerTest {

    private final FakeElasticsearchClient client = new FakeElasticsearchClient();
    private final RagIndexMapping mapping = new RagIndexMapping();
    private final RagProperties properties = new RagProperties();
    private final RagIndexManager manager = new RagIndexManager();

    private RagIndexManager manager() {
        manager.client = client;
        manager.mapping = mapping;
        manager.properties = properties;
        mapping.properties = properties;
        return manager;
    }

    @Test
    void missingIndexIsCreatedAndAliasIsAttached() {
        RagIndexManager target = manager();
        client.indexPresent = false;
        client.aliasPresent = false;

        RagIndexManager.IndexState state = target.ensureReady();

        assertTrue(state.createdIndex());
        assertTrue(state.aliasSwitched());
        assertTrue(client.calls.contains("PUT /rag_chunk_quarkus_v1"));
        assertTrue(client.calls.contains("POST /_aliases"));
    }

    @Test
    void existingIndexAndAliasAreLeftUntouched() {
        RagIndexManager target = manager();
        client.indexPresent = true;
        client.aliasPresent = true;

        RagIndexManager.IndexState state = target.ensureReady();

        assertFalse(state.createdIndex());
        assertFalse(state.aliasSwitched());
        assertTrue(client.calls.stream().noneMatch(call -> call.startsWith("PUT") || call.startsWith("POST")));
    }

    @Test
    void existingAliasIsNotStolenByAnotherIndex() {
        RagIndexManager target = manager();
        client.indexPresent = true;
        client.aliasPresent = true;

        target.ensureReady();

        assertFalse(client.calls.contains("POST /_aliases"));
    }

    @Test
    void missingAliasIsAddedWithWriteIndexFlag() {
        RagIndexManager target = manager();
        client.indexPresent = true;
        client.aliasPresent = false;

        RagIndexManager.IndexState state = target.ensureReady();

        assertFalse(state.createdIndex());
        assertTrue(state.aliasSwitched());
        assertTrue(client.aliasBodies.get(0).contains("is_write_index"));
        assertTrue(client.aliasBodies.get(0).contains("rag_chunk_quarkus_current"));
    }

    @Test
    void chunkWritesUseTheChunkIdAsDocumentId() {
        RagIndexManager target = manager();
        client.indexPresent = true;
        client.aliasPresent = true;

        target.indexChunk("chk_123", Json.createObjectBuilder().add("chunk_id", "chk_123").build());

        assertTrue(client.calls.contains("PUT /rag_chunk_quarkus_v1/_doc/chk_123"));
    }

    @Test
    void chunkDeleteUsesTheChunkIdAsDocumentId() {
        RagIndexManager target = manager();
        client.indexPresent = true;
        client.aliasPresent = true;

        target.deleteChunk("chk_123");

        assertTrue(client.calls.contains("DELETE /rag_chunk_quarkus_v1/_doc/chk_123"));
    }

    private static final class FakeElasticsearchClient extends ElasticsearchClient {

        private final List<String> calls = new ArrayList<>();
        private final List<String> aliasBodies = new ArrayList<>();
        private boolean indexPresent = true;
        private boolean aliasPresent = true;

        @Override
        public boolean exists(String path) {
            calls.add("HEAD " + path);
            return indexPresent;
        }

        @Override
        public Optional<JsonObject> findJson(String path) {
            calls.add("GET " + path);
            if (!aliasPresent) {
                return Optional.empty();
            }
            return Optional.of(Json.createObjectBuilder().build());
        }

        @Override
        public JsonObject putJson(String path, JsonObject body) {
            calls.add("PUT " + path);
            return Json.createObjectBuilder().build();
        }

        @Override
        public JsonObject postJson(String path, JsonObject body) {
            calls.add("POST " + path);
            aliasBodies.add(body.toString());
            return Json.createObjectBuilder().build();
        }

        @Override
        public JsonObject deleteJson(String path) {
            calls.add("DELETE " + path);
            return Json.createObjectBuilder().build();
        }
    }
}
