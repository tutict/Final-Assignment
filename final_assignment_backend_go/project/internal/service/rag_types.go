package service

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"errors"
	"fmt"
	"math"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
)

const ragIDDelimiter = "\x1f"

type RagConfig struct {
	Enabled              bool
	IndexingEnabled      bool
	EmbeddingEnabled     bool
	RetrievalEnabled     bool
	EmbeddingProvider    string
	EmbeddingModel       string
	MaxBatchSize         int
	MaxRequeueLimit      int
	MaxEmbeddingAttempts int
	RetryDelay           time.Duration
	RetrievalTopK        int
	VectorWeight         float64
	BM25Weight           float64
	MinScore             float64
	CandidateMultiplier  int
	RRFRankConstant      int
	RerankEnabled        bool
	RerankLexicalWeight  float64
}

func DefaultRagConfig() RagConfig {
	return RagConfig{
		Enabled:              true,
		IndexingEnabled:      true,
		EmbeddingEnabled:     true,
		RetrievalEnabled:     false,
		EmbeddingProvider:    "unassigned",
		EmbeddingModel:       "unassigned",
		MaxBatchSize:         500,
		MaxRequeueLimit:      5000,
		MaxEmbeddingAttempts: 3,
		RetryDelay:           30 * time.Second,
		RetrievalTopK:        10,
		VectorWeight:         0.6,
		BM25Weight:           0.4,
		MinScore:             0.2,
		CandidateMultiplier:  3,
		RRFRankConstant:      60,
		RerankEnabled:        true,
		RerankLexicalWeight:  0.15,
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

type RagEmbeddingProvider interface {
	ProviderName() string
	ModelName() string
	Embed(ctx context.Context, text string) ([]float32, error)
}

type RagVectorStore interface {
	IndexChunk(
		ctx context.Context,
		document domain.RagDocument,
		chunk domain.RagChunk,
		vector []float32,
		provider string,
		model string,
	) error
}

type RagSearchBackend interface {
	BM25Search(ctx context.Context, normalizedQuery string, aclFilter RagAccessFilter, limit int) ([]RagRetrievalResult, error)
	VectorSearch(ctx context.Context, queryVector []float32, aclFilter RagAccessFilter, limit int) ([]RagRetrievalResult, error)
}

type RagQueryRequest struct {
	Query      string   `json:"query"`
	TopK       *int     `json:"topK,omitempty"`
	UserID     string   `json:"userId,omitempty"`
	Roles      []string `json:"roles,omitempty"`
	Department string   `json:"department,omitempty"`
}

type RagQueryResponse struct {
	Results []RagRetrievalResult `json:"results"`
}

type RagRetrievalQuery struct {
	NormalizedQuery string
	AccessContext   RagAccessContext
	TopK            int
}

type RagAccessContext struct {
	UserID     string
	Roles      []string
	Department string
}

type RagAccessFilter struct {
	UserID     string
	Roles      []string
	Department string
}

type RagRetrievalResult struct {
	ChunkID        string         `json:"chunkId"`
	DocumentID     string         `json:"documentId"`
	Content        string         `json:"content"`
	Title          string         `json:"title"`
	SourceType     string         `json:"sourceType"`
	SourceTable    string         `json:"sourceTable"`
	SourceID       string         `json:"sourceId"`
	SourceField    string         `json:"sourceField"`
	Route          string         `json:"route"`
	BM25Score      float64        `json:"bm25Score"`
	VectorScore    float64        `json:"vectorScore"`
	FinalScore     float64        `json:"finalScore"`
	Metadata       map[string]any `json:"metadata"`
	ACLScope       string         `json:"-"`
	ACLRoles       []string       `json:"-"`
	ACLUserIDs     []string       `json:"-"`
	ACLDepartments []string       `json:"-"`
}

func (r RagRetrievalResult) WithScores(bm25Score, vectorScore, finalScore float64) RagRetrievalResult {
	r.BM25Score = bm25Score
	r.VectorScore = vectorScore
	r.FinalScore = finalScore
	if r.Metadata == nil {
		r.Metadata = map[string]any{}
	}
	return r
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
	if config.MaxEmbeddingAttempts <= 0 {
		config.MaxEmbeddingAttempts = defaults.MaxEmbeddingAttempts
	}
	if config.RetryDelay <= 0 {
		config.RetryDelay = defaults.RetryDelay
	}
	if config.RetrievalTopK <= 0 {
		config.RetrievalTopK = defaults.RetrievalTopK
	}
	if config.VectorWeight <= 0 {
		config.VectorWeight = defaults.VectorWeight
	}
	if config.BM25Weight <= 0 {
		config.BM25Weight = defaults.BM25Weight
	}
	if config.MinScore <= 0 {
		config.MinScore = defaults.MinScore
	}
	if config.CandidateMultiplier <= 0 {
		config.CandidateMultiplier = defaults.CandidateMultiplier
	}
	if config.RRFRankConstant <= 0 {
		config.RRFRankConstant = defaults.RRFRankConstant
	}
	if config.RerankLexicalWeight <= 0 {
		config.RerankLexicalWeight = defaults.RerankLexicalWeight
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

func embeddingHash(chunk domain.RagChunk, vector []float32, provider, model string) string {
	digest := sha256.New()
	digest.Write([]byte(provider))
	digest.Write([]byte(ragIDDelimiter))
	digest.Write([]byte(model))
	digest.Write([]byte(ragIDDelimiter))
	digest.Write([]byte(chunk.ContentHash))
	var buffer [4]byte
	for _, value := range vector {
		binary.BigEndian.PutUint32(buffer[:], math.Float32bits(value))
		digest.Write(buffer[:])
	}
	return hex.EncodeToString(digest.Sum(nil))
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

func clipString(value string, max int) string {
	if max <= 0 || len(value) <= max {
		return value
	}
	return value[:max]
}
