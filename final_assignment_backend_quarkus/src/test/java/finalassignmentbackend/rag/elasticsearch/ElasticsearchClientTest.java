package finalassignmentbackend.rag.elasticsearch;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ElasticsearchClientTest {

    private HttpServer server;
    private ElasticsearchClient client;
    private final List<String> methods = new ArrayList<>();
    private final List<String> bodies = new ArrayList<>();

    @BeforeEach
    void startServer() throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", this::handle);
        server.start();
        client = new ElasticsearchClient();
        client.host = "http://127.0.0.1:" + server.getAddress().getPort();
        client.timeout = Duration.ofSeconds(5);
    }

    @AfterEach
    void stopServer() {
        server.stop(0);
    }

    @Test
    void getJsonParsesObjectBody() {
        respond(200, "{\"hits\":{\"total\":2}}");

        assertEquals(2, client.getJson("/index/_search").getJsonObject("hits").getJsonNumber("total").intValue());
        assertEquals(List.of("GET"), methods);
    }

    @Test
    void findJsonTreats404AsMissing() {
        respond(404, "{\"error\":\"not found\"}");

        assertTrue(client.findJson("/_alias/missing").isEmpty());
    }

    @Test
    void getJsonFailsWithStatusAndBodySnippet() {
        respond(500, "boom  ");

        ElasticsearchException error = assertThrows(ElasticsearchException.class, () -> client.getJson("/index/_search"));
        assertEquals(500, error.status());
        assertTrue(error.getMessage().contains("boom"));
    }

    @Test
    void putJsonSendsRequestBody() {
        respond(200, "{\"result\":\"created\"}");

        client.putJson("/index/_doc/chunk-1", jakarta.json.Json.createObjectBuilder().add("chunk_id", "chunk-1").build());

        assertEquals(List.of("PUT"), methods);
        assertTrue(bodies.get(0).contains("chunk-1"));
    }

    @Test
    void existsReportsPresenceWithoutBody() {
        respond(200, "");

        assertTrue(client.exists("/rag_chunk_quarkus_v1"));
    }

    @Test
    void existsIsFalseForMissingResource() {
        respond(404, "");

        assertFalse(client.exists("/rag_chunk_quarkus_v1"));
    }

    @Test
    void deleteTreatsMissingDocumentAsSuccess() {
        respond(404, "{\"result\":\"not_found\"}");

        client.deleteJson("/rag_chunk_quarkus_v1/_doc/missing");

        assertEquals(List.of("DELETE"), methods);
    }

    @Test
    void unreachableHostRaisesElasticsearchException() {
        client.host = "http://127.0.0.1:1";

        assertThrows(ElasticsearchException.class, () -> client.getJson("/index/_search"));
    }

    private void handle(HttpExchange exchange) throws IOException {
        methods.add(exchange.getRequestMethod());
        try (InputStream stream = exchange.getRequestBody()) {
            bodies.add(new String(stream.readAllBytes(), StandardCharsets.UTF_8));
        }
        byte[] payload = responseBody.getBytes(StandardCharsets.UTF_8);
        exchange.sendResponseHeaders(responseStatus, payload.length == 0 ? -1 : payload.length);
        if (payload.length > 0) {
            exchange.getResponseBody().write(payload);
        }
        exchange.close();
    }

    private int responseStatus = 200;
    private String responseBody = "{}";

    private void respond(int status, String body) {
        this.responseStatus = status;
        this.responseBody = body;
    }
}
