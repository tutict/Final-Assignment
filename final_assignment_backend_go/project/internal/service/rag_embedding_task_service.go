package service

import (
	"context"
	"sync/atomic"
	"time"

	"final_assignment_backend_go/project/internal/domain"
)

type RagEmbeddingTaskService struct {
	tasks   RagEmbeddingTaskStore
	chunks  RagChunkStore
	config  RagConfig
	running atomic.Bool
}

func NewRagEmbeddingTaskService(tasks RagEmbeddingTaskStore, chunks RagChunkStore, config RagConfig) *RagEmbeddingTaskService {
	return &RagEmbeddingTaskService{
		tasks:  tasks,
		chunks: chunks,
		config: normalizeRagConfig(config),
	}
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

	// The actual provider/vector index integration is intentionally a later adapter.
	// This boundary only selects runnable work without mutating external systems.
	return RagEmbeddingBatchResult{
		SelectedTasks: len(tasks),
		Enabled:       true,
	}, nil
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
