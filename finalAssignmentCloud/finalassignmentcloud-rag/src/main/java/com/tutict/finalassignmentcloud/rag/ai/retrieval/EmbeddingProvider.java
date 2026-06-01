package com.tutict.finalassignmentcloud.rag.ai.retrieval;

public interface EmbeddingProvider {

    default String providerName() {
        return getClass().getSimpleName();
    }

    default String modelName() {
        return providerName() + "-" + dimensions();
    }

    int dimensions();

    float[] embed(String text);
}

