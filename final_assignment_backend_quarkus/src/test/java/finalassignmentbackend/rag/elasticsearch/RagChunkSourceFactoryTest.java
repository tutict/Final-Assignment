package finalassignmentbackend.rag.elasticsearch;

import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import jakarta.json.JsonArray;
import jakarta.json.JsonObject;
import jakarta.json.JsonString;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RagChunkSourceFactoryTest {

    private final RagChunkSourceFactory factory = new RagChunkSourceFactory();

    @Test
    void sourceCarriesDocumentChunkAndVector() {
        JsonObject source = factory.build(document("{\"suite\":\"ragas\"}"), chunk(), new float[]{1f, 0f, 0f},
                "ollama", "nomic-embed-text");

        assertEquals("chunk-1", source.getString("chunk_id"));
        assertEquals("doc-1", source.getString("document_id"));
        assertEquals("违章处理流程", source.getString("content"));
        assertEquals("PUBLIC", source.getString("acl_scope"));
        assertEquals("ollama", source.getString("embedding_provider"));
        assertEquals(3, source.getJsonArray("embedding").size());
        assertEquals("ragas", source.getJsonObject("metadata").getString("suite"));
    }

    @Test
    void aclListsAreTakenFromMetadataAliases() {
        JsonObject source = factory.build(document("{\"aclRoles\":[\"SUPER_ADMIN\"],"
                        + "\"aclUserIds\":[\"driver-1001\"],\"aclDepartments\":[\"finance\"]}"),
                chunk(), new float[]{0f, 1f, 0f}, "ollama", "nomic-embed-text");

        assertEquals(List.of("SUPER_ADMIN"), strings(source.getJsonArray("acl_roles")));
        assertEquals(List.of("driver-1001"), strings(source.getJsonArray("acl_user_ids")));
        assertEquals(List.of("finance"), strings(source.getJsonArray("acl_departments")));
    }

    @Test
    void aclListsFallBackToUnderscoreAndCamelAliases() {
        JsonObject source = factory.build(document("{\"acl_roles\":[\"ADMIN\"],\"userIds\":[\"ce@ce.com\"],"
                        + "\"departments\":[\"traffic\"]}"),
                chunk(), new float[]{0f, 0f, 1f}, "ollama", "nomic-embed-text");

        assertEquals(List.of("ADMIN"), strings(source.getJsonArray("acl_roles")));
        assertEquals(List.of("ce@ce.com"), strings(source.getJsonArray("acl_user_ids")));
        assertEquals(List.of("traffic"), strings(source.getJsonArray("acl_departments")));
    }

    @Test
    void missingMetadataYieldsEmptyAclLists() {
        JsonObject source = factory.build(document("{}"), chunk(), new float[]{0f, 0f, 1f},
                "ollama", "nomic-embed-text");

        assertTrue(source.getJsonArray("acl_roles").isEmpty());
        assertTrue(source.getJsonArray("acl_user_ids").isEmpty());
        assertTrue(source.getJsonArray("acl_departments").isEmpty());
    }

    @Test
    void brokenMetadataIsKeptAsRawTextInsteadOfFailing() {
        JsonObject metadata = factory.metadata("not-json");

        assertTrue(metadata.containsKey("rawMetadata"));
        assertTrue(metadata.containsKey("metadataParseError"));
    }

    private static List<String> strings(JsonArray array) {
        List<String> values = new ArrayList<>();
        array.forEach(item -> values.add(((JsonString) item).getString()));
        return values;
    }

    private static RagDocument document(String metadataJson) {
        RagDocument document = new RagDocument();
        document.setId("doc-1");
        document.setSourceType("BUSINESS");
        document.setSourceTable("offense");
        document.setSourceId("source-1");
        document.setSourceVersion("v1");
        document.setTitle("违章处理流程");
        document.setAclScope("PUBLIC");
        document.setMetadataJson(metadataJson);
        document.setStatus("READY");
        return document;
    }

    private static RagChunk chunk() {
        RagChunk chunk = new RagChunk();
        chunk.setId("chunk-1");
        chunk.setDocumentId("doc-1");
        chunk.setContent("违章处理流程");
        chunk.setContentHash("hash-1");
        chunk.setChunkNo(0);
        chunk.setStatus("EMBEDDED");
        return chunk;
    }
}
