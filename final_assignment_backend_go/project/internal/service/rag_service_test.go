package service

import (
	"context"
	"testing"
	"time"

	"final_assignment_backend_go/project/internal/domain"
)

func TestNormalizeRagSourceDocumentDefaults(t *testing.T) {
	source, err := NormalizeRagSourceDocument(domain.RagSourceDocument{
		SourceTable: "appeal_record",
		SourceID:    "42",
	})
	if err != nil {
		t.Fatalf("NormalizeRagSourceDocument() error = %v", err)
	}
	if source.SourceType != "BUSINESS" {
		t.Fatalf("SourceType = %q", source.SourceType)
	}
	if source.SourceVersion != "v1" {
		t.Fatalf("SourceVersion = %q", source.SourceVersion)
	}
	if source.Title != "appeal_record:42" {
		t.Fatalf("Title = %q", source.Title)
	}
	if source.ACLScope != "PUBLIC" {
		t.Fatalf("ACLScope = %q", source.ACLScope)
	}
}

func TestRagIndexingServiceIndexesDocumentChunksAndTasks(t *testing.T) {
	ctx := context.Background()
	documents := newMemoryRagDocumentStore()
	chunks := newMemoryRagChunkStore()
	tasks := newMemoryRagEmbeddingTaskStore()
	config := DefaultRagConfig()

	documentService := NewRagDocumentService(documents, chunks, tasks, config)
	chunkService := NewRagChunkService(chunks)
	taskService := NewRagEmbeddingTaskService(tasks, chunks, config)
	indexingService := NewRagIndexingService(
		documentService,
		chunkService,
		taskService,
		NewSimpleRagChunker(10, 0),
		config,
	)

	result, err := indexingService.Index(ctx, domain.RagSourceDocument{
		SourceTable:   "manual_rag_document",
		SourceID:      "manual-1",
		SourceVersion: "v1",
		Title:         "manual",
		Content:       "abcdefghijklmnopqrstuvwxyz",
	})
	if err != nil {
		t.Fatalf("Index() error = %v", err)
	}
	if result.Document.ID == "" {
		t.Fatal("document ID is empty")
	}
	if len(result.Chunks) != 3 {
		t.Fatalf("chunks = %d, want 3", len(result.Chunks))
	}
	if len(result.EmbeddingTasks) != len(result.Chunks) {
		t.Fatalf("tasks = %d, chunks = %d", len(result.EmbeddingTasks), len(result.Chunks))
	}

	overview, err := documentService.Overview(ctx)
	if err != nil {
		t.Fatalf("Overview() error = %v", err)
	}
	if overview.DocumentCount != 1 || overview.ChunkCount != 3 || overview.PendingEmbeddingTaskCount != 3 {
		t.Fatalf("unexpected overview: %+v", overview)
	}
}

func TestRagBackfillServiceRunBatches(t *testing.T) {
	provider := &memoryRagBatchProvider{
		batches: [][]domain.RagSourceDocument{
			{
				{SourceTable: "offense_type_dict", SourceID: "1", Content: "one"},
				{SourceTable: "appeal_record", SourceID: "2", Content: "two"},
			},
			{
				{SourceTable: "offense_type_dict", SourceID: "3", Content: "three"},
			},
		},
	}
	indexer := &memoryRagIndexer{}
	service := NewRagBackfillService([]RagSourceBatchProvider{provider}, indexer, DefaultRagConfig())

	result, err := service.RunBatches(context.Background(), 1, 100, 5)
	if err != nil {
		t.Fatalf("RunBatches() error = %v", err)
	}
	if result.ProcessedDocuments != 3 {
		t.Fatalf("ProcessedDocuments = %d, want 3", result.ProcessedDocuments)
	}
	if result.ProcessedPages != 2 {
		t.Fatalf("ProcessedPages = %d, want 2", result.ProcessedPages)
	}
}

func TestRagIndexMigrationServiceRequeuesChunks(t *testing.T) {
	ctx := context.Background()
	chunks := newMemoryRagChunkStore()
	tasks := newMemoryRagEmbeddingTaskStore()
	now := time.Now().UTC()
	if err := chunks.Save(ctx, &domain.RagChunk{
		ID:         "chunk-1",
		DocumentID: "doc-1",
		Status:     domain.RagChunkStatusEmbedded,
		UpdatedAt:  now,
	}); err != nil {
		t.Fatalf("save chunk: %v", err)
	}

	taskService := NewRagEmbeddingTaskService(tasks, chunks, DefaultRagConfig())
	indexService := NewRagIndexMigrationService(
		NewRagIndexManagerService(&memoryVectorIndexManager{}),
		taskService,
		DefaultRagConfig(),
	)

	result, err := indexService.MigrateToNewIndex(ctx, "rag_chunks_v2", true, 10)
	if err != nil {
		t.Fatalf("MigrateToNewIndex() error = %v", err)
	}
	if !result.CreatedIndex || !result.AliasSwitched {
		t.Fatalf("unexpected migration result: %+v", result)
	}
	if result.CreatedTasks != 1 || result.RequeuedChunks != 1 {
		t.Fatalf("unexpected requeue result: %+v", result)
	}
}

type memoryRagDocumentStore struct {
	items map[string]domain.RagDocument
}

func newMemoryRagDocumentStore() *memoryRagDocumentStore {
	return &memoryRagDocumentStore{items: make(map[string]domain.RagDocument)}
}

func (s *memoryRagDocumentStore) Save(_ context.Context, document *domain.RagDocument) error {
	s.items[document.ID] = *document
	return nil
}

func (s *memoryRagDocumentStore) FindByID(_ context.Context, id string) (*domain.RagDocument, error) {
	document, ok := s.items[id]
	if !ok {
		return nil, ErrNotFound
	}
	return &document, nil
}

func (s *memoryRagDocumentStore) List(_ context.Context, _ string, _ int) ([]domain.RagDocument, error) {
	documents := make([]domain.RagDocument, 0, len(s.items))
	for _, document := range s.items {
		documents = append(documents, document)
	}
	return documents, nil
}

func (s *memoryRagDocumentStore) Count(context.Context) (int64, error) {
	return int64(len(s.items)), nil
}

func (s *memoryRagDocumentStore) CountByStatus(_ context.Context, status string) (int64, error) {
	var count int64
	for _, document := range s.items {
		if document.Status == status {
			count++
		}
	}
	return count, nil
}

func (s *memoryRagDocumentStore) DeleteByID(_ context.Context, id string) (int64, error) {
	if _, ok := s.items[id]; !ok {
		return 0, nil
	}
	delete(s.items, id)
	return 1, nil
}

type memoryRagChunkStore struct {
	items map[string]domain.RagChunk
}

func newMemoryRagChunkStore() *memoryRagChunkStore {
	return &memoryRagChunkStore{items: make(map[string]domain.RagChunk)}
}

func (s *memoryRagChunkStore) Save(_ context.Context, chunk *domain.RagChunk) error {
	s.items[chunk.ID] = *chunk
	return nil
}

func (s *memoryRagChunkStore) FindByID(_ context.Context, id string) (*domain.RagChunk, error) {
	chunk, ok := s.items[id]
	if !ok {
		return nil, ErrNotFound
	}
	return &chunk, nil
}

func (s *memoryRagChunkStore) ListByDocumentID(_ context.Context, documentID string) ([]domain.RagChunk, error) {
	var chunks []domain.RagChunk
	for _, chunk := range s.items {
		if chunk.DocumentID == documentID {
			chunks = append(chunks, chunk)
		}
	}
	return chunks, nil
}

func (s *memoryRagChunkStore) ListForRequeue(_ context.Context, limit int) ([]domain.RagChunk, error) {
	chunks := make([]domain.RagChunk, 0, len(s.items))
	for _, chunk := range s.items {
		if len(chunks) == limit {
			break
		}
		chunks = append(chunks, chunk)
	}
	return chunks, nil
}

func (s *memoryRagChunkStore) Count(context.Context) (int64, error) {
	return int64(len(s.items)), nil
}

func (s *memoryRagChunkStore) ResetEmbedding(_ context.Context, chunkID, model string, now time.Time) (int64, error) {
	chunk, ok := s.items[chunkID]
	if !ok {
		return 0, nil
	}
	chunk.Status = domain.RagChunkStatusPendingEmbedding
	chunk.EmbeddingModel = model
	chunk.EmbeddingHash = ""
	chunk.UpdatedAt = now
	s.items[chunkID] = chunk
	return 1, nil
}

func (s *memoryRagChunkStore) DeleteByDocumentID(_ context.Context, documentID string) (int64, error) {
	var count int64
	for id, chunk := range s.items {
		if chunk.DocumentID == documentID {
			delete(s.items, id)
			count++
		}
	}
	return count, nil
}

type memoryRagEmbeddingTaskStore struct {
	items map[string]domain.RagEmbeddingTask
}

func newMemoryRagEmbeddingTaskStore() *memoryRagEmbeddingTaskStore {
	return &memoryRagEmbeddingTaskStore{items: make(map[string]domain.RagEmbeddingTask)}
}

func (s *memoryRagEmbeddingTaskStore) Save(_ context.Context, task *domain.RagEmbeddingTask) error {
	s.items[task.ID] = *task
	return nil
}

func (s *memoryRagEmbeddingTaskStore) FindByID(_ context.Context, id string) (*domain.RagEmbeddingTask, error) {
	task, ok := s.items[id]
	if !ok {
		return nil, ErrNotFound
	}
	return &task, nil
}

func (s *memoryRagEmbeddingTaskStore) ListRunnable(_ context.Context, limit int, _ time.Time) ([]domain.RagEmbeddingTask, error) {
	tasks := make([]domain.RagEmbeddingTask, 0, len(s.items))
	for _, task := range s.items {
		if len(tasks) == limit {
			break
		}
		if task.Status == domain.RagEmbeddingTaskStatusPending || task.Status == domain.RagEmbeddingTaskStatusFailed {
			tasks = append(tasks, task)
		}
	}
	return tasks, nil
}

func (s *memoryRagEmbeddingTaskStore) CountByStatus(_ context.Context, status string) (int64, error) {
	var count int64
	for _, task := range s.items {
		if task.Status == status {
			count++
		}
	}
	return count, nil
}

func (s *memoryRagEmbeddingTaskStore) ResetByChunkID(_ context.Context, chunkID, provider, model string, now time.Time) (int64, error) {
	var count int64
	for id, task := range s.items {
		if task.ChunkID == chunkID {
			task.Provider = provider
			task.Model = model
			task.Status = domain.RagEmbeddingTaskStatusPending
			task.AttemptCount = 0
			task.NextRetryAt = nil
			task.LastError = ""
			task.UpdatedAt = now
			s.items[id] = task
			count++
		}
	}
	return count, nil
}

func (s *memoryRagEmbeddingTaskStore) DeleteByChunkID(_ context.Context, chunkID string) (int64, error) {
	var count int64
	for id, task := range s.items {
		if task.ChunkID == chunkID {
			delete(s.items, id)
			count++
		}
	}
	return count, nil
}

type memoryRagBatchProvider struct {
	batches [][]domain.RagSourceDocument
}

func (p *memoryRagBatchProvider) LoadBatch(_ context.Context, page, _ int) ([]domain.RagSourceDocument, bool, error) {
	index := page - 1
	if index < 0 || index >= len(p.batches) {
		return nil, false, nil
	}
	return p.batches[index], index+1 < len(p.batches), nil
}

type memoryRagIndexer struct {
	indexed []domain.RagSourceDocument
}

func (i *memoryRagIndexer) Index(_ context.Context, source domain.RagSourceDocument) (RagIndexingResult, error) {
	i.indexed = append(i.indexed, source)
	return RagIndexingResult{}, nil
}

type memoryVectorIndexManager struct{}

func (m *memoryVectorIndexManager) CreateIndex(context.Context, string) (bool, error) {
	return true, nil
}

func (m *memoryVectorIndexManager) SwitchWriteAlias(context.Context, string) (bool, error) {
	return true, nil
}

func (m *memoryVectorIndexManager) DefaultIndexName() string {
	return "rag_chunks"
}

func (m *memoryVectorIndexManager) AliasName() string {
	return "rag_chunks_write"
}
