package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import com.fasterxml.jackson.databind.JsonNode;
import com.tutict.finalassignmentbackend.ai.provider.AiProviderProperties;
import com.tutict.finalassignmentbackend.rag.config.RagProperties;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.Map;

@Component
@ConditionalOnProperty(prefix = "rag.embedding", name = "provider", havingValue = "ollama")
public class OllamaEmbeddingProvider implements EmbeddingProvider {

    private final RagProperties properties;
    private final AiProviderProperties aiProviderProperties;
    private final WebClient.Builder webClientBuilder;

    public OllamaEmbeddingProvider(
            RagProperties properties,
            AiProviderProperties aiProviderProperties,
            WebClient.Builder webClientBuilder
    ) {
        this.properties = properties;
        this.aiProviderProperties = aiProviderProperties;
        this.webClientBuilder = webClientBuilder;
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
        JsonNode response = client()
                .post()
                .uri("/api/embeddings")
                .bodyValue(Map.of(
                        "model", modelName(),
                        "prompt", text == null ? "" : text
                ))
                .retrieve()
                .bodyToMono(JsonNode.class)
                .timeout(aiProviderProperties.getProvider().getTimeout())
                .block();
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

    private WebClient client() {
        return webClientBuilder.baseUrl(aiProviderProperties.getOllama().getBaseUrl()).build();
    }

    private static float[] parseVector(JsonNode response) {
        if (response == null || !response.has("embedding") || !response.get("embedding").isArray()) {
            throw new IllegalStateException("Ollama embedding response did not contain an embedding array");
        }
        JsonNode embedding = response.get("embedding");
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
