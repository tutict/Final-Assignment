package com.tutict.finalassignmentbackend.ai.rag.retrieval;

public interface EmbeddingProvider {

    int dimensions();

    float[] embed(String text);
}
