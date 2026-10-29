package finalassignmentbackend.rag.config;

import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.time.Duration;

@ApplicationScoped
public class RagProperties {

    @ConfigProperty(name = "rag.enabled", defaultValue = "true")
    boolean enabled = true;

    @ConfigProperty(name = "rag.indexing.enabled", defaultValue = "true")
    boolean indexingEnabled = true;

    @ConfigProperty(name = "rag.chunk.size", defaultValue = "500")
    int chunkSize = 500;

    @ConfigProperty(name = "rag.chunk.overlap", defaultValue = "100")
    int chunkOverlap = 100;

    @ConfigProperty(name = "rag.elasticsearch.enabled", defaultValue = "true")
    boolean elasticsearchEnabled = true;

    @ConfigProperty(name = "rag.elasticsearch.timeout", defaultValue = "10s")
    Duration elasticsearchTimeout = Duration.ofSeconds(10);

    @ConfigProperty(name = "rag.index.name", defaultValue = "rag_chunk_quarkus_v1")
    String indexName = "rag_chunk_quarkus_v1";

    @ConfigProperty(name = "rag.index.alias", defaultValue = "rag_chunk_quarkus_current")
    String indexAlias = "rag_chunk_quarkus_current";

    @ConfigProperty(name = "rag.index.text-analyzer", defaultValue = "standard")
    String indexTextAnalyzer = "standard";

    @ConfigProperty(name = "rag.index.shards", defaultValue = "1")
    int indexShards = 1;

    @ConfigProperty(name = "rag.index.replicas", defaultValue = "0")
    int indexReplicas = 0;

    @ConfigProperty(name = "rag.index.refresh-interval", defaultValue = "30s")
    String indexRefreshInterval = "30s";

    @ConfigProperty(name = "rag.embedding.enabled", defaultValue = "false")
    boolean embeddingEnabled = false;

    @ConfigProperty(name = "rag.embedding.provider", defaultValue = "ollama")
    String embeddingProvider = "ollama";

    @ConfigProperty(name = "rag.embedding.model", defaultValue = "nomic-embed-text")
    String embeddingModel = "nomic-embed-text";

    @ConfigProperty(name = "rag.embedding.dimensions", defaultValue = "768")
    int embeddingDimensions = 768;

    @ConfigProperty(name = "rag.embedding.base-url", defaultValue = "http://localhost:11434")
    String embeddingBaseUrl = "http://localhost:11434";

    @ConfigProperty(name = "rag.embedding.batch-size", defaultValue = "25")
    int embeddingBatchSize = 25;

    @ConfigProperty(name = "rag.embedding.max-attempts", defaultValue = "3")
    int embeddingMaxAttempts = 3;

    @ConfigProperty(name = "rag.embedding.retry-delay", defaultValue = "1m")
    Duration embeddingRetryDelay = Duration.ofMinutes(1);

    @ConfigProperty(name = "rag.embedding.timeout", defaultValue = "30s")
    Duration embeddingTimeout = Duration.ofSeconds(30);

    @ConfigProperty(name = "rag.embedding.request-budget", defaultValue = "20s")
    Duration embeddingRequestBudget = Duration.ofSeconds(20);

    @ConfigProperty(name = "rag.embedding.scheduler-enabled", defaultValue = "false")
    boolean embeddingSchedulerEnabled = false;

    @ConfigProperty(name = "rag.embedding.poll-interval", defaultValue = "30s")
    Duration embeddingPollInterval = Duration.ofSeconds(30);

    @ConfigProperty(name = "rag.retrieval.enabled", defaultValue = "true")
    boolean retrievalEnabled = true;

    @ConfigProperty(name = "rag.retrieval.bm25-weight", defaultValue = "0.8")
    double bm25Weight = 0.8;

    @ConfigProperty(name = "rag.retrieval.vector-weight", defaultValue = "0.2")
    double vectorWeight = 0.2;

    @ConfigProperty(name = "rag.retrieval.min-score", defaultValue = "0.2")
    double minScore = 0.2;

    @ConfigProperty(name = "rag.retrieval.candidate-multiplier", defaultValue = "3")
    int candidateMultiplier = 3;

    @ConfigProperty(name = "rag.retrieval.rrf-rank-constant", defaultValue = "60")
    int rrfRankConstant = 60;

    @ConfigProperty(name = "rag.retrieval.rerank-enabled", defaultValue = "true")
    boolean rerankEnabled = true;

    @ConfigProperty(name = "rag.retrieval.rerank-lexical-weight", defaultValue = "0.15")
    double rerankLexicalWeight = 0.15;

    @ConfigProperty(name = "rag.mysql-fallback-enabled", defaultValue = "true")
    boolean mysqlFallbackEnabled = true;

    public boolean isEnabled() {
        return enabled;
    }

    public boolean isIndexingEnabled() {
        return indexingEnabled;
    }

    public int getChunkSize() {
        return chunkSize;
    }

    public int getChunkOverlap() {
        return chunkOverlap;
    }

    public boolean isElasticsearchEnabled() {
        return elasticsearchEnabled;
    }

    public Duration getElasticsearchTimeout() {
        return elasticsearchTimeout;
    }

    public String getIndexName() {
        return indexName;
    }

    public String getIndexAlias() {
        return indexAlias;
    }

    public String getIndexTextAnalyzer() {
        return indexTextAnalyzer;
    }

    public int getIndexShards() {
        return indexShards;
    }

    public int getIndexReplicas() {
        return indexReplicas;
    }

    public String getIndexRefreshInterval() {
        return indexRefreshInterval;
    }

    public boolean isEmbeddingEnabled() {
        return embeddingEnabled;
    }

    public String getEmbeddingProvider() {
        return embeddingProvider;
    }

    public String getEmbeddingModel() {
        return embeddingModel;
    }

    public int getEmbeddingDimensions() {
        return embeddingDimensions;
    }

    public String getEmbeddingBaseUrl() {
        return embeddingBaseUrl;
    }

    public int getEmbeddingBatchSize() {
        return embeddingBatchSize;
    }

    public int getEmbeddingMaxAttempts() {
        return embeddingMaxAttempts;
    }

    public Duration getEmbeddingRetryDelay() {
        return embeddingRetryDelay;
    }

    public Duration getEmbeddingTimeout() {
        return embeddingTimeout;
    }

    public Duration getEmbeddingRequestBudget() {
        return embeddingRequestBudget;
    }

    public boolean isEmbeddingSchedulerEnabled() {
        return embeddingSchedulerEnabled;
    }

    public Duration getEmbeddingPollInterval() {
        return embeddingPollInterval;
    }

    public boolean isRetrievalEnabled() {
        return retrievalEnabled;
    }

    public double getBm25Weight() {
        return bm25Weight;
    }

    public double getVectorWeight() {
        return vectorWeight;
    }

    public double getMinScore() {
        return minScore;
    }

    public int getCandidateMultiplier() {
        return candidateMultiplier;
    }

    public int getRrfRankConstant() {
        return rrfRankConstant;
    }

    public boolean isRerankEnabled() {
        return rerankEnabled;
    }

    public double getRerankLexicalWeight() {
        return rerankLexicalWeight;
    }

    public boolean isMysqlFallbackEnabled() {
        return mysqlFallbackEnabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public void setIndexingEnabled(boolean indexingEnabled) {
        this.indexingEnabled = indexingEnabled;
    }

    public void setChunkSize(int chunkSize) {
        this.chunkSize = chunkSize;
    }

    public void setChunkOverlap(int chunkOverlap) {
        this.chunkOverlap = chunkOverlap;
    }

    public void setElasticsearchEnabled(boolean elasticsearchEnabled) {
        this.elasticsearchEnabled = elasticsearchEnabled;
    }

    public void setElasticsearchTimeout(Duration elasticsearchTimeout) {
        this.elasticsearchTimeout = elasticsearchTimeout;
    }

    public void setIndexName(String indexName) {
        this.indexName = indexName;
    }

    public void setIndexAlias(String indexAlias) {
        this.indexAlias = indexAlias;
    }

    public void setIndexTextAnalyzer(String indexTextAnalyzer) {
        this.indexTextAnalyzer = indexTextAnalyzer;
    }

    public void setIndexShards(int indexShards) {
        this.indexShards = indexShards;
    }

    public void setIndexReplicas(int indexReplicas) {
        this.indexReplicas = indexReplicas;
    }

    public void setIndexRefreshInterval(String indexRefreshInterval) {
        this.indexRefreshInterval = indexRefreshInterval;
    }

    public void setEmbeddingEnabled(boolean embeddingEnabled) {
        this.embeddingEnabled = embeddingEnabled;
    }

    public void setEmbeddingProvider(String embeddingProvider) {
        this.embeddingProvider = embeddingProvider;
    }

    public void setEmbeddingModel(String embeddingModel) {
        this.embeddingModel = embeddingModel;
    }

    public void setEmbeddingDimensions(int embeddingDimensions) {
        this.embeddingDimensions = embeddingDimensions;
    }

    public void setEmbeddingBaseUrl(String embeddingBaseUrl) {
        this.embeddingBaseUrl = embeddingBaseUrl;
    }

    public void setEmbeddingBatchSize(int embeddingBatchSize) {
        this.embeddingBatchSize = embeddingBatchSize;
    }

    public void setEmbeddingMaxAttempts(int embeddingMaxAttempts) {
        this.embeddingMaxAttempts = embeddingMaxAttempts;
    }

    public void setEmbeddingRetryDelay(Duration embeddingRetryDelay) {
        this.embeddingRetryDelay = embeddingRetryDelay;
    }

    public void setEmbeddingTimeout(Duration embeddingTimeout) {
        this.embeddingTimeout = embeddingTimeout;
    }

    public void setEmbeddingRequestBudget(Duration embeddingRequestBudget) {
        this.embeddingRequestBudget = embeddingRequestBudget;
    }

    public void setEmbeddingSchedulerEnabled(boolean embeddingSchedulerEnabled) {
        this.embeddingSchedulerEnabled = embeddingSchedulerEnabled;
    }

    public void setEmbeddingPollInterval(Duration embeddingPollInterval) {
        this.embeddingPollInterval = embeddingPollInterval;
    }

    public void setRetrievalEnabled(boolean retrievalEnabled) {
        this.retrievalEnabled = retrievalEnabled;
    }

    public void setBm25Weight(double bm25Weight) {
        this.bm25Weight = bm25Weight;
    }

    public void setVectorWeight(double vectorWeight) {
        this.vectorWeight = vectorWeight;
    }

    public void setMinScore(double minScore) {
        this.minScore = minScore;
    }

    public void setCandidateMultiplier(int candidateMultiplier) {
        this.candidateMultiplier = candidateMultiplier;
    }

    public void setRrfRankConstant(int rrfRankConstant) {
        this.rrfRankConstant = rrfRankConstant;
    }

    public void setRerankEnabled(boolean rerankEnabled) {
        this.rerankEnabled = rerankEnabled;
    }

    public void setRerankLexicalWeight(double rerankLexicalWeight) {
        this.rerankLexicalWeight = rerankLexicalWeight;
    }

    public void setMysqlFallbackEnabled(boolean mysqlFallbackEnabled) {
        this.mysqlFallbackEnabled = mysqlFallbackEnabled;
    }
}
