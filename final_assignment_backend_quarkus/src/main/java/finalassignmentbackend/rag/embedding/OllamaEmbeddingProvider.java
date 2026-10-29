package finalassignmentbackend.rag.embedding;

import finalassignmentbackend.rag.config.RagProperties;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonObject;
import jakarta.json.JsonReader;
import jakarta.json.JsonString;
import jakarta.json.JsonValue;

import java.io.StringReader;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

/**
 * Ollama 向量提供方。
 *
 * <p>优先使用 {@code /api/embeddings}（单条 prompt），旧版本 Ollama 只有 {@code /api/embed}
 * 时按 Spring 参考实现的策略回退。向量维度必须与索引映射一致，否则直接失败，
 * 避免把错误维度的向量写进 ES。
 */
@ApplicationScoped
public class OllamaEmbeddingProvider implements RagEmbeddingProvider {

    private static final int MAX_BODY_SNIPPET = 500;

    private final HttpClient httpClient;
    private final RagProperties properties;

    @Inject
    public OllamaEmbeddingProvider(RagProperties properties) {
        this(properties, HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build());
    }

    OllamaEmbeddingProvider(RagProperties properties, HttpClient httpClient) {
        this.properties = properties;
        this.httpClient = httpClient;
    }

    @Override
    public String providerName() {
        return "ollama";
    }

    @Override
    public String modelName() {
        String model = properties.getEmbeddingModel();
        return model == null || model.isBlank() ? "nomic-embed-text" : model.trim();
    }

    @Override
    public int dimensions() {
        return Math.max(1, properties.getEmbeddingDimensions());
    }

    @Override
    public float[] embed(String text) {
        String prompt = text == null ? "" : text;
        JsonObject response;
        try {
            response = request("/api/embeddings", Json.createObjectBuilder()
                    .add("model", modelName())
                    .add("prompt", prompt)
                    .build());
        } catch (RagEmbeddingException error) {
            if (!shouldTryEmbedEndpoint(error.status())) {
                throw error;
            }
            response = request("/api/embed", Json.createObjectBuilder()
                    .add("model", modelName())
                    .add("input", prompt)
                    .build());
        }
        float[] vector = parseVector(response);
        if (vector.length != dimensions()) {
            throw new RagEmbeddingException("Embedding dimension mismatch for model " + modelName()
                    + ": expected " + dimensions() + ", got " + vector.length
                    + ". Set RAG_EMBEDDING_DIMENSIONS to the model output size.", 0);
        }
        return normalize(vector);
    }

    private JsonObject request(String path, JsonObject body) {
        HttpRequest request = HttpRequest.newBuilder(resolveUri(path))
                .timeout(timeout())
                .header("Content-Type", "application/json; charset=utf-8")
                .header("Accept", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(body.toString(), StandardCharsets.UTF_8))
                .build();
        try {
            HttpResponse<String> response = httpClient.send(request,
                    HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            String responseBody = response.body() == null ? "" : response.body();
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new RagEmbeddingException("Ollama embedding request failed with HTTP "
                        + response.statusCode() + " from POST " + request.uri() + ": " + clip(responseBody),
                        response.statusCode());
            }
            return parse(responseBody);
        } catch (InterruptedException error) {
            Thread.currentThread().interrupt();
            throw new RagEmbeddingException("Ollama embedding request was interrupted", error);
        } catch (RagEmbeddingException error) {
            throw error;
        } catch (Exception error) {
            throw new RagEmbeddingException("Ollama embedding request failed", error);
        }
    }

    private static JsonObject parse(String body) {
        if (body == null || body.isBlank()) {
            throw new RagEmbeddingException("Ollama embedding response body was empty", 0);
        }
        try (JsonReader reader = Json.createReader(new StringReader(body))) {
            return reader.readObject();
        } catch (Exception error) {
            throw new RagEmbeddingException("Ollama embedding response was not valid JSON", error);
        }
    }

    private static float[] parseVector(JsonObject response) {
        JsonArray embedding = null;
        if (response.containsKey("embedding")
                && response.get("embedding").getValueType() == JsonValue.ValueType.ARRAY) {
            embedding = response.getJsonArray("embedding");
        } else if (response.containsKey("embeddings")
                && response.get("embeddings").getValueType() == JsonValue.ValueType.ARRAY) {
            JsonArray embeddings = response.getJsonArray("embeddings");
            if (!embeddings.isEmpty() && embeddings.get(0).getValueType() == JsonValue.ValueType.ARRAY) {
                embedding = embeddings.getJsonArray(0);
            }
        }
        if (embedding == null) {
            throw new RagEmbeddingException("Ollama embedding response did not contain an embedding array", 0);
        }
        float[] vector = new float[embedding.size()];
        for (int i = 0; i < embedding.size(); i++) {
            vector[i] = (float) embedding.getJsonNumber(i).doubleValue();
        }
        return vector;
    }

    private static float[] normalize(float[] vector) {
        double sum = 0;
        for (float value : vector) {
            sum += value * value;
        }
        double norm = Math.sqrt(sum);
        if (norm == 0) {
            return vector;
        }
        for (int i = 0; i < vector.length; i++) {
            vector[i] = (float) (vector[i] / norm);
        }
        return vector;
    }

    /** 只有「端点不存在或参数不被接受」才值得回退到 /api/embed。 */
    private static boolean shouldTryEmbedEndpoint(int status) {
        return status == 400 || status == 404 || status == 405;
    }

    private Duration timeout() {
        Duration configured = properties.getEmbeddingTimeout();
        return configured == null || configured.isZero() || configured.isNegative()
                ? Duration.ofSeconds(30)
                : configured;
    }

    private URI resolveUri(String path) {
        String base = properties.getEmbeddingBaseUrl();
        if (base == null || base.isBlank()) {
            base = "http://localhost:11434";
        }
        return URI.create(base.trim()).resolve(path);
    }

    private static String clip(String value) {
        if (value == null) {
            return "";
        }
        return value.length() <= MAX_BODY_SNIPPET ? value : value.substring(0, MAX_BODY_SNIPPET);
    }
}
