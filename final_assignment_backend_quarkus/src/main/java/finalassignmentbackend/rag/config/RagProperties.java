package finalassignmentbackend.rag.config;

import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@ApplicationScoped
public class RagProperties {
    @ConfigProperty(name = "rag.enabled", defaultValue = "true")
    boolean enabled;
    @ConfigProperty(name = "rag.indexing.enabled", defaultValue = "true")
    boolean indexingEnabled;
    @ConfigProperty(name = "rag.chunk.size", defaultValue = "500")
    int chunkSize;
    @ConfigProperty(name = "rag.chunk.overlap", defaultValue = "100")
    int chunkOverlap;
    @ConfigProperty(name = "rag.embedding.provider", defaultValue = "unassigned")
    String embeddingProvider;
    @ConfigProperty(name = "rag.embedding.model", defaultValue = "unassigned")
    String embeddingModel;

    public boolean isEnabled() { return enabled; }
    public boolean isIndexingEnabled() { return indexingEnabled; }
    public int getChunkSize() { return chunkSize; }
    public int getChunkOverlap() { return chunkOverlap; }
    public String getEmbeddingProvider() { return embeddingProvider; }
    public String getEmbeddingModel() { return embeddingModel; }
}
