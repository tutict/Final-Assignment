package service

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
)

const ragIDDelimiter = "\x1f"

type RagConfig struct {
	Enabled           bool
	IndexingEnabled   bool
	EmbeddingEnabled  bool
	EmbeddingProvider string
	EmbeddingModel    string
	MaxBatchSize      int
	MaxRequeueLimit   int
}

func DefaultRagConfig() RagConfig {
	return RagConfig{
		Enabled:           true,
		IndexingEnabled:   true,
		EmbeddingEnabled:  true,
		EmbeddingProvider: "unassigned",
		EmbeddingModel:    "unassigned",
		MaxBatchSize:      500,
		MaxRequeueLimit:   5000,
	}
}

type RagDocumentStore interface {
	Save(ctx context.Context, document *domain.RagDocument) error
	FindByID(ctx context.Context, id string) (*domain.RagDocument, error)
	List(ctx context.Context, query string, limit int) ([]domain.RagDocument, error)
	Count(ctx context.Context) (int64, error)
	CountByStatus(ctx context.Context, status string) (int64, error)
	DeleteByID(ctx context.Context, id string) (int64, error)
}

type RagChunkStore interface {
	Save(ctx context.Context, chunk *domain.RagChunk) error
	FindByID(ctx context.Context, id string) (*domain.RagChunk, error)
	ListByDocumentID(ctx context.Context, documentID string) ([]domain.RagChunk, error)
	ListForRequeue(ctx context.Context, limit int) ([]domain.RagChunk, error)
	Count(ctx context.Context) (int64, error)
	ResetEmbedding(ctx context.Context, chunkID, model string, now time.Time) (int64, error)
	DeleteByDocumentID(ctx context.Context, documentID string) (int64, error)
}

type RagEmbeddingTaskStore interface {
	Save(ctx context.Context, task *domain.RagEmbeddingTask) error
	FindByID(ctx context.Context, id string) (*domain.RagEmbeddingTask, error)
	ListRunnable(ctx context.Context, limit int, now time.Time) ([]domain.RagEmbeddingTask, error)
	CountByStatus(ctx context.Context, status string) (int64, error)
	ResetByChunkID(ctx context.Context, chunkID, provider, model string, now time.Time) (int64, error)
	DeleteByChunkID(ctx context.Context, chunkID string) (int64, error)
}

type RagChunker interface {
	Chunk(source domain.RagSourceDocument) ([]RagSourceChunk, error)
}

type RagSourceChunk struct {
	ChunkNo     int
	Content     string
	ContentHash string
	TokenCount  int
	CharCount   int
	SourceField string
}

type RagSourceBatchProvider interface {
	LoadBatch(ctx context.Context, page, size int) ([]domain.RagSourceDocument, bool, error)
}

type RagVectorIndexManager interface {
	CreateIndex(ctx context.Context, indexName string) (bool, error)
	SwitchWriteAlias(ctx context.Context, indexName string) (bool, error)
	DefaultIndexName() string
	AliasName() string
}

type RagOverview struct {
	Enabled                     bool  `json:"enabled"`
	IndexingEnabled             bool  `json:"indexingEnabled"`
	DocumentCount               int64 `json:"documentCount"`
	ReadyDocumentCount          int64 `json:"readyDocumentCount"`
	ChunkCount                  int64 `json:"chunkCount"`
	PendingEmbeddingTaskCount   int64 `json:"pendingEmbeddingTaskCount"`
	FailedEmbeddingTaskCount    int64 `json:"failedEmbeddingTaskCount"`
	SucceededEmbeddingTaskCount int64 `json:"succeededEmbeddingTaskCount"`
	PoisonedEmbeddingTaskCount  int64 `json:"poisonedEmbeddingTaskCount"`
}

type RagIndexingResult struct {
	Document       domain.RagDocument        `json:"document"`
	Chunks         []domain.RagChunk         `json:"chunks"`
	EmbeddingTasks []domain.RagEmbeddingTask `json:"embeddingTasks"`
}

type RagBackfillResult struct {
	ProcessedDocuments int  `json:"processedDocuments"`
	FailedDocuments    int  `json:"failedDocuments"`
	HasMore            bool `json:"hasMore"`
	Enabled            bool `json:"enabled"`
}

type RagBackfillRunResult struct {
	ProcessedDocuments int  `json:"processedDocuments"`
	FailedDocuments    int  `json:"failedDocuments"`
	ProcessedPages     int  `json:"processedPages"`
	HasMore            bool `json:"hasMore"`
	Enabled            bool `json:"enabled"`
}

type RagEmbeddingBatchResult struct {
	SelectedTasks  int  `json:"selectedTasks"`
	SucceededTasks int  `json:"succeededTasks"`
	FailedTasks    int  `json:"failedTasks"`
	Enabled        bool `json:"enabled"`
	AlreadyRunning bool `json:"alreadyRunning"`
}

type RagRequeueResult struct {
	RequeuedChunks int `json:"requeuedChunks"`
	RequeuedTasks  int `json:"requeuedTasks"`
	CreatedTasks   int `json:"createdTasks"`
}

type RagIndexMigrationResult struct {
	Enabled         bool   `json:"enabled"`
	CreatedIndex    bool   `json:"createdIndex"`
	AliasSwitched   bool   `json:"aliasSwitched"`
	TargetIndexName string `json:"targetIndexName"`
	AliasName       string `json:"aliasName"`
	RequeuedChunks  int    `json:"requeuedChunks"`
	RequeuedTasks   int    `json:"requeuedTasks"`
	CreatedTasks    int    `json:"createdTasks"`
	Message         string `json:"message"`
}

func normalizeRagConfig(config RagConfig) RagConfig {
	defaults := DefaultRagConfig()
	if config.EmbeddingProvider == "" {
		config.EmbeddingProvider = defaults.EmbeddingProvider
	}
	if config.EmbeddingModel == "" {
		config.EmbeddingModel = defaults.EmbeddingModel
	}
	if config.MaxBatchSize <= 0 {
		config.MaxBatchSize = defaults.MaxBatchSize
	}
	if config.MaxRequeueLimit <= 0 {
		config.MaxRequeueLimit = defaults.MaxRequeueLimit
	}
	return config
}

func normalizeLimit(value, max int) int {
	if value < 1 {
		value = 1
	}
	if max > 0 && value > max {
		return max
	}
	return value
}

func stableRagID(prefix string, parts ...string) string {
	sum := sha256.Sum256([]byte(strings.Join(parts, ragIDDelimiter)))
	return fmt.Sprintf("%s_%s", prefix, hex.EncodeToString(sum[:])[:32])
}

func sha256Hex(value string) string {
	sum := sha256.Sum256([]byte(value))
	return hex.EncodeToString(sum[:])
}

func defaultIfBlank(value, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return strings.TrimSpace(value)
}

func errAsNotFound(err error) bool {
	return errors.Is(err, ErrNotFound)
}

func nowUTC() time.Time {
	return time.Now().UTC()
}
