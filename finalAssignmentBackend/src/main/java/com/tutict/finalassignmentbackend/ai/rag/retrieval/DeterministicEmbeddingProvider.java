package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import com.tutict.finalassignmentbackend.rag.config.RagProperties;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

@Component
@ConditionalOnProperty(prefix = "rag.embedding", name = "provider", havingValue = "deterministic", matchIfMissing = true)
public class DeterministicEmbeddingProvider implements EmbeddingProvider {

    private final int dimensions;

    public DeterministicEmbeddingProvider(RagProperties properties) {
        this.dimensions = Math.max(1, properties.getEmbedding().getDimensions());
    }

    @Override
    public String providerName() {
        return "deterministic";
    }

    @Override
    public String modelName() {
        return "deterministic-" + dimensions;
    }

    @Override
    public int dimensions() {
        return dimensions;
    }

    @Override
    public float[] embed(String text) {
        float[] vector = new float[dimensions()];
        byte[] seed = sha256(text == null ? "" : text);
        for (int i = 0; i < vector.length; i++) {
            int value = seed[i % seed.length] & 0xff;
            vector[i] = (value - 127.5f) / 127.5f;
        }
        normalize(vector);
        return vector;
    }

    private static byte[] sha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return digest.digest(value.getBytes(StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA-256 is not available", error);
        }
    }

    private static void normalize(float[] vector) {
        double sum = 0;
        for (float value : vector) {
            sum += value * value;
        }
        double norm = Math.sqrt(sum);
        if (norm == 0) {
            return;
        }
        for (int i = 0; i < vector.length; i++) {
            vector[i] = (float) (vector[i] / norm);
        }
    }
}
