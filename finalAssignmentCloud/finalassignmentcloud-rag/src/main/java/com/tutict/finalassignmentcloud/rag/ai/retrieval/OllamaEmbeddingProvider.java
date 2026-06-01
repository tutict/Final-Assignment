package com.tutict.finalassignmentcloud.rag.ai.retrieval;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.rag.ai.provider.AiProviderProperties;
import com.tutict.finalassignmentcloud.rag.config.RagProperties;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@Component
@ConditionalOnProperty(prefix = "rag.embedding", name = "provider", havingValue = "ollama")
public class OllamaEmbeddingProvider implements EmbeddingProvider {

    private final RagProperties properties;
    private final AiProviderProperties aiProviderProperties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    public OllamaEmbeddingProvider(
            RagProperties properties,
            AiProviderProperties aiProviderProperties,
            ObjectMapper objectMapper
    ) {
        this.properties = properties;
        this.aiProviderProperties = aiProviderProperties;
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(aiProviderProperties.getProvider().getTimeout())
                .build();
    }

    @Override
    public String providerName() {
        return "ollama";
    }

    @Override
    public String modelName() {
        return properties.getEmbedding().getModel();
    }

    @Override
    public int dimensions() {
        return Math.max(1, properties.getEmbedding().getDimensions());
    }

    @Override
    public float[] embed(String text) {
        if (!aiProviderProperties.getOllama().isEnabled()) {
            throw new IllegalStateException("Ollama provider is disabled");
        }
        String prompt = text == null ? "" : text;
        JsonNode response;
        try {
            response = requestEmbedding("/api/embeddings", Map.of(
                    "model", modelName(),
                    "prompt", prompt
            ));
        } catch (RuntimeException error) {
            if (!shouldTryEmbedEndpoint(error)) {
                throw error;
            }
            response = requestEmbedding("/api/embed", Map.of(
                    "model", modelName(),
                    "input", prompt
            ));
        }
        float[] vector = parseVector(response);
        if (vector.length != dimensions()) {
            throw new IllegalStateException(
                    "Embedding dimension mismatch for model " + modelName()
                            + ": expected " + dimensions()
                            + ", got " + vector.length
                            + ". Set RAG_EMBEDDING_DIMENSIONS to the model output size."
            );
        }
        return normalize(vector);
    }

    private JsonNode requestEmbedding(String uri, Map<String, String> payload) {
        try {
            HttpRequest request = HttpRequest.newBuilder(resolveUri(uri))
                    .timeout(aiProviderProperties.getProvider().getTimeout())
                    .header("Content-Type", "application/json; charset=utf-8")
                    .header("Accept", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(
                            objectMapper.writeValueAsString(payload),
                            StandardCharsets.UTF_8
                    ))
                    .build();
            HttpResponse<String> response = httpClient.send(
                    request,
                    HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8)
            );
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new OllamaEmbeddingException(response.statusCode(), request.uri(), response.body());
            }
            return objectMapper.readTree(response.body());
        } catch (JsonProcessingException error) {
            throw new IllegalStateException("Failed to serialize Ollama embedding request", error);
        } catch (IOException error) {
            throw new IllegalStateException("Ollama embedding request failed", error);
        } catch (InterruptedException error) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Ollama embedding request was interrupted", error);
        }
    }

    private URI resolveUri(String path) {
        return URI.create(aiProviderProperties.getOllama().getBaseUrl()).resolve(path);
    }

    private static boolean shouldTryEmbedEndpoint(RuntimeException error) {
        Throwable current = error;
        while (current != null) {
            if (current instanceof OllamaEmbeddingException responseException) {
                int status = responseException.statusCode();
                return status == 400 || status == 404 || status == 405;
            }
            current = current.getCause();
        }
        return false;
    }

    private static float[] parseVector(JsonNode response) {
        JsonNode embedding = null;
        if (response != null && response.has("embedding") && response.get("embedding").isArray()) {
            embedding = response.get("embedding");
        } else if (response != null && response.has("embeddings") && response.get("embeddings").isArray()
                && !response.get("embeddings").isEmpty() && response.get("embeddings").get(0).isArray()) {
            embedding = response.get("embeddings").get(0);
        }
        if (embedding == null) {
            throw new IllegalStateException("Ollama embedding response did not contain an embedding array");
        }
        float[] vector = new float[embedding.size()];
        for (int i = 0; i < embedding.size(); i++) {
            vector[i] = (float) embedding.get(i).asDouble();
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

    private static final class OllamaEmbeddingException extends RuntimeException {

        private final int statusCode;

        private OllamaEmbeddingException(int statusCode, URI uri, String body) {
            super("Ollama embedding request failed with HTTP " + statusCode + " from POST " + uri
                    + (body == null || body.isBlank() ? "" : ": " + body));
            this.statusCode = statusCode;
        }

        private int statusCode() {
            return statusCode;
        }
    }
}

