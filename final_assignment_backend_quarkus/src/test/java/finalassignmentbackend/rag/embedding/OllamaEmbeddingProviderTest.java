package finalassignmentbackend.rag.embedding;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import finalassignmentbackend.rag.config.RagProperties;
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

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class OllamaEmbeddingProviderTest {

    private HttpServer server;
    private RagProperties properties;
    private final List<String> paths = new ArrayList<>();
    private final List<String> bodies = new ArrayList<>();

    private int responseStatus = 200;
    private String responseBody = "{}";
    private int embedStatus = 200;
    private String embedBody = "{\"embeddings\":[[0,1,0]]}";

    @BeforeEach
    void startServer() throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", this::handle);
        server.start();
        properties = new RagProperties();
        properties.setEmbeddingBaseUrl("http://127.0.0.1:" + server.getAddress().getPort());
        properties.setEmbeddingDimensions(3);
        properties.setEmbeddingTimeout(Duration.ofSeconds(5));
    }

    @AfterEach
    void stopServer() {
        server.stop(0);
    }

    @Test
    void embeddingsEndpointReturnsNormalizedVector() {
        respond(200, "{\"embedding\":[3,4,0]}");

        float[] vector = provider().embed("违章处理流程");

        assertEquals(List.of("/api/embeddings"), paths);
        assertEquals(0.6f, vector[0], 1e-6);
        assertEquals(0.8f, vector[1], 1e-6);
        assertEquals(0.0f, vector[2], 1e-6);
        assertTrue(bodies.get(0).contains("\"prompt\""));
    }

    @Test
    void missingEmbeddingsEndpointFallsBackToEmbedEndpoint() {
        responseStatus = 404;
        responseBody = "{\"error\":\"not found\"}";

        float[] vector = provider().embed("违章处理流程");

        assertEquals(List.of("/api/embeddings", "/api/embed"), paths);
        assertEquals(0.0f, vector[0], 1e-6);
        assertEquals(1.0f, vector[1], 1e-6);
        assertTrue(bodies.get(1).contains("\"input\""));
    }

    @Test
    void dimensionMismatchFailsInsteadOfReturningUsableVector() {
        respond(200, "{\"embedding\":[1,2]}");

        RagEmbeddingException error = assertThrows(RagEmbeddingException.class, () -> provider().embed("文本"));

        assertTrue(error.getMessage().contains("dimension mismatch"));
    }

    @Test
    void malformedResponseIsReportedAsEmbeddingFailure() {
        respond(200, "not-json");

        RagEmbeddingException error = assertThrows(RagEmbeddingException.class, () -> provider().embed("文本"));

        assertNotNull(error.getMessage());
    }

    @Test
    void serverErrorIsNotRetriedOnEmbedEndpoint() {
        respond(500, "boom");

        RagEmbeddingException error = assertThrows(RagEmbeddingException.class, () -> provider().embed("文本"));

        assertEquals(500, error.status());
        assertEquals(List.of("/api/embeddings"), paths);
    }

    @Test
    void responseWithoutEmbeddingArrayFails() {
        respond(200, "{\"message\":\"ok\"}");

        RagEmbeddingException error = assertThrows(RagEmbeddingException.class, () -> provider().embed("文本"));

        assertTrue(error.getMessage().contains("embedding array"));
    }

    private OllamaEmbeddingProvider provider() {
        return new OllamaEmbeddingProvider(properties);
    }

    private void handle(HttpExchange exchange) throws IOException {
        String path = exchange.getRequestURI().getPath();
        paths.add(path);
        try (InputStream stream = exchange.getRequestBody()) {
            bodies.add(new String(stream.readAllBytes(), StandardCharsets.UTF_8));
        }
        int status = responseStatus;
        String body = responseBody;
        if ("/api/embed".equals(path)) {
            status = embedStatus;
            body = embedBody;
        }
        byte[] payload = body.getBytes(StandardCharsets.UTF_8);
        exchange.sendResponseHeaders(status, payload.length == 0 ? -1 : payload.length);
        if (payload.length > 0) {
            exchange.getResponseBody().write(payload);
        }
        exchange.close();
    }

    private void respond(int status, String body) {
        this.responseStatus = status;
        this.responseBody = body;
    }
}
