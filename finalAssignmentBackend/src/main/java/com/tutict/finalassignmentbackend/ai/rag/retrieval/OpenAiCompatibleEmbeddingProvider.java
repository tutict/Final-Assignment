package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.ai.chat.AiRateLimitException;
import com.tutict.finalassignmentbackend.ai.chat.ExternalApiSlotLimiter;
import com.tutict.finalassignmentbackend.ai.provider.AiProviderProperties;
import com.tutict.finalassignmentbackend.rag.config.RagProperties;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
@ConditionalOnProperty(prefix = "rag.embedding", name = "provider", havingValue = "openai-compatible")
public class OpenAiCompatibleEmbeddingProvider implements EmbeddingProvider {

    private final RagProperties properties;
    private final AiProviderProperties aiProviderProperties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;
    private final ExternalApiSlotLimiter slotLimiter;

    public OpenAiCompatibleEmbeddingProvider(
            RagProperties properties,
            AiProviderProperties aiProviderProperties,
            ObjectMapper objectMapper
    ) {
        this(properties, aiProviderProperties, objectMapper, null);
    }

    @org.springframework.beans.factory.annotation.Autowired
    public OpenAiCompatibleEmbeddingProvider(
            RagProperties properties,
            AiProviderProperties aiProviderProperties,
            ObjectMapper objectMapper,
            ObjectProvider<ExternalApiSlotLimiter> slotLimiter
    ) {
        this.properties = properties;
        this.aiProviderProperties = aiProviderProperties;
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(aiProviderProperties.getProvider().getTimeout())
                .build();
        this.slotLimiter = slotLimiter == null ? null : slotLimiter.getIfAvailable();
    }

    @Override
    public String providerName() {
        return "openai-compatible";
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
        if (!aiProviderProperties.getOpenaiCompatible().isEnabled()) {
            throw new IllegalStateException("OpenAI-compatible provider is disabled");
        }
        return embedWithRetry(text);
    }

    private float[] embedWithRetry(String text) {
        int maxRetries = Math.max(0, aiProviderProperties.getOpenaiCompatible().getMaxRateLimitRetries());
        AiRateLimitException last = null;
        for (int attempt = 0; attempt <= maxRetries; attempt++) {
            try {
                return embedUnprotected(text);
            } catch (AiRateLimitException rateLimit) {
                last = rateLimit;
                if (attempt == maxRetries) {
                    throw rateLimit;
                }
                sleepQuietly(rateLimit.retryAfter());
            }
        }
        throw last == null ? new IllegalStateException("OpenAI-compatible embedding failed") : last;
    }

    private float[] embedUnprotected(String text) {
        if (slotLimiter == null) {
            return embedDirect(text);
        }
        return slotLimiter.call(() -> embedDirect(text));
    }

    private float[] embedDirect(String text) {
        String prompt = text == null ? "" : text;
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("model", modelName());
        payload.put("input", prompt);
        JsonNode response = requestEmbedding("/embeddings", payload);
        float[] vector = parseVector(response);
        if (vector.length != dimensions()) {
            throw new IllegalStateException(
                    "Embedding dimension mismatch for model " + modelName()
                            + ": expected " + dimensions()
                            + ", got " + vector.length
            );
        }
        return normalize(vector);
    }

    private JsonNode requestEmbedding(String path, Map<String, Object> payload) {
        try {
            HttpRequest.Builder builder = HttpRequest.newBuilder(resolveUri(path))
                    .timeout(aiProviderProperties.getProvider().getTimeout())
                    .header("Content-Type", "application/json; charset=utf-8")
                    .header("Accept", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(
                            objectMapper.writeValueAsString(payload),
                            StandardCharsets.UTF_8
                    ));
            String apiKey = aiProviderProperties.getOpenaiCompatible().getApiKey();
            if (apiKey != null && !apiKey.isBlank()) {
                builder.header("Authorization", "Bearer " + apiKey);
            }
            HttpResponse<String> response = httpClient.send(
                    builder.build(),
                    HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8)
            );
            if (response.statusCode() == 429) {
                Duration retryAfter = Duration.ofSeconds(1);
                String retryRaw = response.headers().firstValue("Retry-After").orElse("1");
                try {
                    long seconds = Long.parseLong(retryRaw.trim());
                    retryAfter = seconds <= 0 ? Duration.ofMillis(200) : Duration.ofSeconds(seconds);
                } catch (NumberFormatException ignored) {
                    retryAfter = Duration.ofSeconds(1);
                }
                throw new AiRateLimitException(retryAfter);
            }
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new IllegalStateException("OpenAI-compatible embedding failed with HTTP " + response.statusCode());
            }
            return objectMapper.readTree(response.body());
        } catch (JsonProcessingException error) {
            throw new IllegalStateException("Failed to serialize OpenAI-compatible embedding request", error);
        } catch (AiRateLimitException error) {
            throw error;
        } catch (IOException error) {
            throw new IllegalStateException("OpenAI-compatible embedding request failed", error);
        } catch (InterruptedException error) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("OpenAI-compatible embedding request was interrupted", error);
        }
    }

    private URI resolveUri(String path) {
        String base = aiProviderProperties.getOpenaiCompatible().getBaseUrl();
        if (base == null || base.isBlank()) {
            throw new IllegalStateException("OpenAI-compatible base URL is not configured");
        }
        if (!base.endsWith("/")) {
            base = base + "/";
        }
        return URI.create(base).resolve(path.startsWith("/") ? path.substring(1) : path);
    }

    private static void sleepQuietly(Duration delay) {
        try {
            Thread.sleep(Math.max(50, delay.toMillis()));
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            throw new AiRateLimitException(delay);
        }
    }

    private static float[] parseVector(JsonNode response) {
        JsonNode embedding = null;
        if (response != null && response.has("data") && response.get("data").isArray()
                && !response.get("data").isEmpty()) {
            JsonNode first = response.get("data").get(0);
            if (first.has("embedding") && first.get("embedding").isArray()) {
                embedding = first.get("embedding");
            }
        } else if (response != null && response.has("embedding") && response.get("embedding").isArray()) {
            embedding = response.get("embedding");
        }
        if (embedding == null) {
            throw new IllegalStateException("OpenAI-compatible embedding response did not contain an embedding array");
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
}
