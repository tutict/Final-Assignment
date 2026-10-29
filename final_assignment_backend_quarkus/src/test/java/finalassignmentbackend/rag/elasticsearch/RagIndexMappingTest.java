package finalassignmentbackend.rag.elasticsearch;

import finalassignmentbackend.rag.config.RagProperties;
import jakarta.json.JsonObject;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RagIndexMappingTest {

    private final RagProperties properties = new RagProperties();
    private final RagIndexMapping mapping = new RagIndexMapping();

    @Test
    void mappingCoversTheSpringFieldSet() {
        mapping.properties = properties;

        JsonObject fields = mapping.mapping().getJsonObject("properties");

        for (String field : new String[]{"chunk_id", "document_id", "content", "title", "source_type",
                "source_table", "source_id", "source_field", "source_version", "route", "acl_scope",
                "acl_roles", "acl_user_ids", "acl_departments", "embedding_provider", "embedding_model",
                "metadata", "embedding"}) {
            assertTrue(fields.containsKey(field), "mapping must declare " + field);
        }
        assertEquals("keyword", fields.getJsonObject("source_id").getString("type"));
        assertEquals("text", fields.getJsonObject("content").getString("type"));
    }

    @Test
    void embeddingIsDenseVectorWithConfiguredDimensions() {
        mapping.properties = properties;

        JsonObject embedding = mapping.mapping().getJsonObject("properties").getJsonObject("embedding");

        assertEquals("dense_vector", embedding.getString("type"));
        assertEquals(768, embedding.getInt("dims"));
        assertEquals("cosine", embedding.getString("similarity"));
    }

    @Test
    void settingsFollowShardReplicaAndRefreshDefaults() {
        mapping.properties = properties;

        JsonObject index = mapping.settings().getJsonObject("index");

        assertEquals(1, index.getInt("number_of_shards"));
        assertEquals(0, index.getInt("number_of_replicas"));
        assertEquals("30s", index.getString("refresh_interval"));
    }

    @Test
    void createBodyCarriesSettingsAndMappings() {
        mapping.properties = properties;

        JsonObject body = mapping.createBody();

        assertTrue(body.containsKey("settings"));
        assertTrue(body.containsKey("mappings"));
        assertTrue(body.getJsonObject("mappings").getJsonObject("properties").containsKey("embedding"));
    }
}
