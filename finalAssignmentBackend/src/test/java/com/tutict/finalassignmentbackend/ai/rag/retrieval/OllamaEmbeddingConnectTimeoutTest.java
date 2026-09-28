package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTimeoutPreemptively;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.ai.provider.AiProviderProperties;
import com.tutict.finalassignmentbackend.rag.config.RagProperties;
import java.time.Duration;
import org.junit.jupiter.api.Test;

class OllamaEmbeddingConnectTimeoutTest {

    @Test
    void deadModelDoesNotKeepTheProviderTimeout() {
        AiProviderProperties ai = new AiProviderProperties();
        ai.getProvider().setTimeout(Duration.ofSeconds(60));
        ai.getOllama().setEnabled(true);
        ai.getOllama().setBaseUrl("http://192.0.2.1:81");
        RagProperties rag = new RagProperties();
        rag.getEmbedding().setModel("unused");
        rag.getEmbedding().setDimensions(1);

        OllamaEmbeddingProvider provider = new OllamaEmbeddingProvider(rag, ai, new ObjectMapper());
        assertTimeoutPreemptively(Duration.ofSeconds(3), () ->
                assertThrows(IllegalStateException.class, () -> provider.embed("ping")));
    }
}
