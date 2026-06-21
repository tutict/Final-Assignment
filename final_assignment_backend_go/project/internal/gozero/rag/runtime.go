package rag

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/gozero/config"
	"final_assignment_backend_go/project/internal/repo"
	"final_assignment_backend_go/project/internal/service"

	elasticsearch "github.com/elastic/go-elasticsearch/v8"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

const (
	defaultIndexName      = "rag_chunk"
	defaultAliasName      = "rag_chunk_current"
	defaultUploadBytes    = 8 * 1024 * 1024
	defaultEmbeddingDims  = 384
	defaultOllamaBaseURL  = "http://127.0.0.1:11434"
	defaultOllamaTimeout  = 30 * time.Second
	defaultMaxBatchSize   = 500
	defaultMaxRequeueSize = 5000
)

type Runtime struct {
	Enabled bool
	Config  service.RagConfig

	Documents      *service.RagDocumentService
	Indexing       *service.RagIndexingService
	Backfill       *service.RagBackfillService
	EmbeddingTasks *service.RagEmbeddingTaskService
	Migration      *service.RagIndexMigrationService
	UploadParser   *UploadParser
	Query          *service.RagQueryService

	db    *gorm.DB
	sqlDB *sql.DB
}

func NewRuntime(conf config.RagConf) (*Runtime, error) {
	conf = normalizeConf(conf)
	if !conf.Enabled {
		return DisabledRuntime(), nil
	}
	if strings.TrimSpace(conf.MySQLDSN) == "" {
		return nil, fmt.Errorf("Rag.MySQLDSN is required when Rag.Enabled is true")
	}

	provider, err := NewEmbeddingProvider(conf)
	if err != nil {
		return nil, err
	}
	serviceConfig := toServiceConfig(conf, provider)

	db, err := gorm.Open(mysql.Open(conf.MySQLDSN), &gorm.Config{})
	if err != nil {
		return nil, fmt.Errorf("open RAG MySQL connection: %w", err)
	}
	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("get RAG SQL DB: %w", err)
	}
	if conf.AutoMigrate {
		if err := db.AutoMigrate(&domain.RagDocument{}, &domain.RagChunk{}, &domain.RagEmbeddingTask{}); err != nil {
			_ = sqlDB.Close()
			return nil, fmt.Errorf("auto-migrate RAG tables: %w", err)
		}
	}

	documentRepo := repo.NewRagDocumentRepo(db)
	chunkRepo := repo.NewRagChunkRepo(db)
	taskRepo := repo.NewRagEmbeddingTaskRepo(db)

	var indexManager *ElasticsearchIndexManager
	if len(conf.ElasticsearchAddresses) > 0 {
		client, err := elasticsearch.NewClient(elasticsearch.Config{
			Addresses: conf.ElasticsearchAddresses,
			Username:  conf.ElasticsearchUsername,
			Password:  conf.ElasticsearchPassword,
		})
		if err != nil {
			_ = sqlDB.Close()
			return nil, fmt.Errorf("create Elasticsearch client: %w", err)
		}
		indexManager = NewElasticsearchIndexManager(client, ElasticsearchIndexConfig{
			IndexName:        conf.ElasticsearchIndex,
			AliasName:        conf.ElasticsearchAlias,
			Dimensions:       conf.EmbeddingDimensions,
			NumberOfShards:   1,
			NumberOfReplicas: 0,
			RefreshInterval:  "30s",
			TextAnalyzer:     "standard",
		})
	} else if conf.EmbeddingEnabled || conf.RetrievalEnabled {
		_ = sqlDB.Close()
		return nil, fmt.Errorf("Rag.ElasticsearchAddresses is required when Rag.EmbeddingEnabled or Rag.RetrievalEnabled is true")
	}

	documentService := service.NewRagDocumentService(documentRepo, chunkRepo, taskRepo, serviceConfig)
	chunkService := service.NewRagChunkService(chunkRepo)
	embeddingTaskService := service.NewRagEmbeddingTaskService(taskRepo, chunkRepo, serviceConfig).
		WithProcessing(documentRepo, provider, indexManager)
	indexingService := service.NewRagIndexingService(
		documentService,
		chunkService,
		embeddingTaskService,
		service.NewSimpleRagChunker(1200, 150),
		serviceConfig,
	)
	indexManagerService := service.NewRagIndexManagerService(indexManager)

	return &Runtime{
		Enabled:        true,
		Config:         serviceConfig,
		Documents:      documentService,
		Indexing:       indexingService,
		Backfill:       service.NewRagBackfillService(NewBusinessSourceProviders(db), indexingService, serviceConfig),
		EmbeddingTasks: embeddingTaskService,
		Migration:      service.NewRagIndexMigrationService(indexManagerService, embeddingTaskService, serviceConfig),
		UploadParser:   NewUploadParser(conf.MaxUploadBytes),
		Query:          service.NewRagQueryService(indexManager, provider, serviceConfig),
		db:             db,
		sqlDB:          sqlDB,
	}, nil
}

func DisabledRuntime() *Runtime {
	config := service.DefaultRagConfig()
	config.Enabled = false
	config.IndexingEnabled = false
	config.EmbeddingEnabled = false
	config.RetrievalEnabled = false
	return &Runtime{Enabled: false, Config: config}
}

func (r *Runtime) Close() error {
	if r == nil || r.sqlDB == nil {
		return nil
	}
	return r.sqlDB.Close()
}

func (r *Runtime) Ready() bool {
	return r != nil && r.Enabled && r.Documents != nil
}

func normalizeConf(conf config.RagConf) config.RagConf {
	defaults := service.DefaultRagConfig()
	rerankExplicitlyDisabled := !conf.RerankEnabled && conf.RerankLexicalWeight > 0
	if conf.ElasticsearchIndex == "" {
		conf.ElasticsearchIndex = defaultIndexName
	}
	if conf.ElasticsearchAlias == "" {
		conf.ElasticsearchAlias = defaultAliasName
	}
	if conf.EmbeddingProvider == "" {
		conf.EmbeddingProvider = "deterministic"
	}
	if conf.EmbeddingDimensions <= 0 {
		conf.EmbeddingDimensions = defaultEmbeddingDims
	}
	if conf.EmbeddingModel == "" {
		conf.EmbeddingModel = conf.EmbeddingProvider + "-" + fmt.Sprint(conf.EmbeddingDimensions)
	}
	if conf.MaxBatchSize <= 0 {
		conf.MaxBatchSize = defaultMaxBatchSize
	}
	if conf.MaxRequeueLimit <= 0 {
		conf.MaxRequeueLimit = defaultMaxRequeueSize
	}
	if conf.MaxUploadBytes <= 0 {
		conf.MaxUploadBytes = defaultUploadBytes
	}
	if conf.RetrievalTopK <= 0 {
		conf.RetrievalTopK = defaults.RetrievalTopK
	}
	if conf.VectorWeight <= 0 {
		conf.VectorWeight = defaults.VectorWeight
	}
	if conf.BM25Weight <= 0 {
		conf.BM25Weight = defaults.BM25Weight
	}
	if conf.MinScore <= 0 {
		conf.MinScore = defaults.MinScore
	}
	if conf.CandidateMultiplier <= 0 {
		conf.CandidateMultiplier = defaults.CandidateMultiplier
	}
	if conf.RRFRankConstant <= 0 {
		conf.RRFRankConstant = defaults.RRFRankConstant
	}
	if conf.RetrievalEnabled && !rerankExplicitlyDisabled {
		conf.RerankEnabled = defaults.RerankEnabled
	}
	if conf.RerankLexicalWeight <= 0 {
		conf.RerankLexicalWeight = defaults.RerankLexicalWeight
	}
	if conf.OllamaBaseURL == "" {
		conf.OllamaBaseURL = defaultOllamaBaseURL
	}
	if conf.OllamaTimeoutMillis <= 0 {
		conf.OllamaTimeoutMillis = int(defaultOllamaTimeout / time.Millisecond)
	}
	return conf
}

func toServiceConfig(conf config.RagConf, provider service.RagEmbeddingProvider) service.RagConfig {
	serviceConfig := service.DefaultRagConfig()
	serviceConfig.Enabled = conf.Enabled
	serviceConfig.IndexingEnabled = conf.IndexingEnabled
	serviceConfig.EmbeddingEnabled = conf.EmbeddingEnabled
	serviceConfig.RetrievalEnabled = conf.RetrievalEnabled
	serviceConfig.EmbeddingProvider = provider.ProviderName()
	serviceConfig.EmbeddingModel = provider.ModelName()
	serviceConfig.MaxBatchSize = conf.MaxBatchSize
	serviceConfig.MaxRequeueLimit = conf.MaxRequeueLimit
	serviceConfig.RetrievalTopK = conf.RetrievalTopK
	serviceConfig.VectorWeight = conf.VectorWeight
	serviceConfig.BM25Weight = conf.BM25Weight
	serviceConfig.MinScore = conf.MinScore
	serviceConfig.CandidateMultiplier = conf.CandidateMultiplier
	serviceConfig.RRFRankConstant = conf.RRFRankConstant
	serviceConfig.RerankEnabled = conf.RerankEnabled
	serviceConfig.RerankLexicalWeight = conf.RerankLexicalWeight
	return serviceConfig
}
