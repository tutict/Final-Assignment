package service

import (
	"context"
	"fmt"
	"sync/atomic"
	"time"

	"final_assignment_backend_go/project/internal/domain"
)

type RagEmbeddingTaskService struct {
	tasks     RagEmbeddingTaskStore
	chunks    RagChunkStore
	documents RagDocumentStore
	provider  RagEmbeddingProvider
	vectors   RagVectorStore
	config    RagConfig
	running   atomic.Bool
}

func NewRagEmbeddingTaskService(tasks RagEmbeddingTaskStore, chunks RagChunkStore, config RagConfig) *RagEmbeddingTaskService {
	return &RagEmbeddingTaskService{
		tasks:  tasks,
		chunks: chunks,
		config: normalizeRagConfig(config),
	}
}

func (s *RagEmbeddingTaskService) WithProcessing(
	documents RagDocumentStore,
	provider RagEmbeddingProvider,
	vectors RagVectorStore,
) *RagEmbeddingTaskService {
	s.documents = documents
	s.provider = provider
	s.vectors = vectors
	return s
}

func (s *RagEmbeddingTaskService) EnsurePendingTask(ctx context.Context, chunk domain.RagChunk, now time.Time) (domain.RagEmbeddingTask, error) {
	provider := defaultIfBlank(s.config.EmbeddingProvider, "unassigned")
	model := defaultIfBlank(s.config.EmbeddingModel, "unassigned")
	taskKey := stableRagID("emb", chunk.ID, provider, model)

	task, err := s.tasks.FindByID(ctx, taskKey)
	if err != nil {
		task = &domain.RagEmbeddingTask{
			ID:           taskKey,
			ChunkID:      chunk.ID,
			TaskKey:      taskKey,
			Provider:     provider,
			Model:        model,
			Status:       domain.RagEmbeddingTaskStatusPending,
			AttemptCount: 0,
			CreatedAt:    now,
			UpdatedAt:    now,
		}
		if err := s.tasks.Save(ctx, task); err != nil {
			return domain.RagEmbeddingTask{}, err
		}
		return *task, nil
	}

	if task.Status != domain.RagEmbeddingTaskStatusSucceeded {
		task.Status = domain.RagEmbeddingTaskStatusPending
		task.NextRetryAt = nil
		task.LastError = ""
	}
	task.Provider = provider
	task.Model = model
	task.UpdatedAt = now
	if err := s.tasks.Save(ctx, task); err != nil {
		return domain.RagEmbeddingTask{}, err
	}
	return *task, nil
}

func (s *RagEmbeddingTaskService) EnsurePendingTasks(ctx context.Context, chunks []domain.RagChunk, now time.Time) ([]domain.RagEmbeddingTask, error) {
	tasks := make([]domain.RagEmbeddingTask, 0, len(chunks))
	for _, chunk := range chunks {
		task, err := s.EnsurePendingTask(ctx, chunk, now)
		if err != nil {
			return nil, err
		}
		tasks = append(tasks, task)
	}
	return tasks, nil
}

func (s *RagEmbeddingTaskService) ProcessPendingBatch(ctx context.Context, limit int) (RagEmbeddingBatchResult, error) {
	if !s.config.Enabled || !s.config.EmbeddingEnabled {
		return RagEmbeddingBatchResult{Enabled: false}, nil
	}
	if !s.running.CompareAndSwap(false, true) {
		return RagEmbeddingBatchResult{Enabled: true, AlreadyRunning: true}, nil
	}
	defer s.running.Store(false)

	limit = normalizeLimit(limit, s.config.MaxBatchSize)
	tasks, err := s.tasks.ListRunnable(ctx, limit, time.Now())
	if err != nil {
		return RagEmbeddingBatchResult{}, err
	}
	if len(tasks) == 0 {
		return RagEmbeddingBatchResult{Enabled: true}, nil
	}
	if s.documents == nil || s.provider == nil || s.vectors == nil {
		return RagEmbeddingBatchResult{}, fmt.Errorf("rag embedding processor is not configured")
	}

	result := RagEmbeddingBatchResult{SelectedTasks: len(tasks), Enabled: true}
	for _, task := range tasks {
		if err := s.processTask(ctx, task); err != nil {
			result.FailedTasks++
			continue
		}
		result.SucceededTasks++
	}
	return result, nil
}

func (s *RagEmbeddingTaskService) processTask(ctx context.Context, task domain.RagEmbeddingTask) error {
	now := time.Now().UTC()
	task.Status = domain.RagEmbeddingTaskStatusRunning
	task.Provider = s.provider.ProviderName()
	task.Model = s.provider.ModelName()
	task.AttemptCount++
	task.NextRetryAt = nil
	task.LastError = ""
	task.UpdatedAt = now
	if err := s.tasks.Save(ctx, &task); err != nil {
		return err
	}

	chunk, err := s.chunks.FindByID(ctx, task.ChunkID)
	if err != nil {
		return s.poisonTask(ctx, task, "RAG chunk does not exist: "+task.ChunkID)
	}
	document, err := s.documents.FindByID(ctx, chunk.DocumentID)
	if err != nil {
		return s.poisonTask(ctx, task, "RAG document does not exist: "+chunk.DocumentID)
	}
	vector, err := s.provider.Embed(ctx, chunk.Content)
	if err != nil {
		return s.failTask(ctx, task, err)
	}
	if err := s.vectors.IndexChunk(ctx, *document, *chunk, vector, s.provider.ProviderName(), s.provider.ModelName()); err != nil {
		return s.failTask(ctx, task, err)
	}

	chunk.Status = domain.RagChunkStatusEmbedded
	chunk.EmbeddingModel = s.provider.ModelName()
	chunk.EmbeddingHash = embeddingHash(*chunk, vector, s.provider.ProviderName(), s.provider.ModelName())
	chunk.UpdatedAt = now
	if err := s.chunks.Save(ctx, chunk); err != nil {
		return err
	}

	task.Status = domain.RagEmbeddingTaskStatusSucceeded
	task.LastError = ""
	task.NextRetryAt = nil
	task.UpdatedAt = now
	return s.tasks.Save(ctx, &task)
}

func (s *RagEmbeddingTaskService) failTask(ctx context.Context, task domain.RagEmbeddingTask, failure error) error {
	now := time.Now().UTC()
	if task.AttemptCount >= s.config.MaxEmbeddingAttempts {
		task.Status = domain.RagEmbeddingTaskStatusPoisoned
		task.NextRetryAt = nil
	} else {
		nextRetry := now.Add(s.config.RetryDelay)
		task.Status = domain.RagEmbeddingTaskStatusFailed
		task.NextRetryAt = &nextRetry
	}
	task.LastError = clipString(failure.Error(), 2000)
	task.UpdatedAt = now
	if err := s.tasks.Save(ctx, &task); err != nil {
		return err
	}
	return failure
}

func (s *RagEmbeddingTaskService) poisonTask(ctx context.Context, task domain.RagEmbeddingTask, message string) error {
	now := time.Now().UTC()
	task.Status = domain.RagEmbeddingTaskStatusPoisoned
	task.LastError = clipString(message, 2000)
	task.NextRetryAt = nil
	task.UpdatedAt = now
	if err := s.tasks.Save(ctx, &task); err != nil {
		return err
	}
	return fmt.Errorf("%s", message)
}

func (s *RagEmbeddingTaskService) RequeueChunk(ctx context.Context, chunkID string, now time.Time) (RagRequeueResult, error) {
	provider := defaultIfBlank(s.config.EmbeddingProvider, "unassigned")
	model := defaultIfBlank(s.config.EmbeddingModel, "unassigned")

	requeuedChunks, err := s.chunks.ResetEmbedding(ctx, chunkID, model, now)
	if err != nil {
		return RagRequeueResult{}, err
	}
	requeuedTasks, err := s.tasks.ResetByChunkID(ctx, chunkID, provider, model, now)
	if err != nil {
		return RagRequeueResult{}, err
	}
	if requeuedTasks > 0 {
		return RagRequeueResult{RequeuedChunks: int(requeuedChunks), RequeuedTasks: int(requeuedTasks)}, nil
	}

	chunk, err := s.chunks.FindByID(ctx, chunkID)
	if err != nil {
		return RagRequeueResult{RequeuedChunks: int(requeuedChunks)}, nil
	}
	if _, err := s.EnsurePendingTask(ctx, *chunk, now); err != nil {
		return RagRequeueResult{}, err
	}
	return RagRequeueResult{RequeuedChunks: int(requeuedChunks), CreatedTasks: 1}, nil
}

func (s *RagEmbeddingTaskService) RequeueChunks(ctx context.Context, limit int, now time.Time) (RagRequeueResult, error) {
	chunks, err := s.chunks.ListForRequeue(ctx, normalizeLimit(limit, s.config.MaxRequeueLimit))
	if err != nil {
		return RagRequeueResult{}, err
	}

	var result RagRequeueResult
	for _, chunk := range chunks {
		chunkResult, err := s.RequeueChunk(ctx, chunk.ID, now)
		if err != nil {
			return RagRequeueResult{}, err
		}
		result.RequeuedChunks += chunkResult.RequeuedChunks
		result.RequeuedTasks += chunkResult.RequeuedTasks
		result.CreatedTasks += chunkResult.CreatedTasks
	}
	return result, nil
}
