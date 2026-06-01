package service

import (
	"context"

	"final_assignment_backend_go/project/internal/domain"
)

type RagIndexer interface {
	Index(ctx context.Context, source domain.RagSourceDocument) (RagIndexingResult, error)
}

type RagBackfillService struct {
	providers []RagSourceBatchProvider
	indexer   RagIndexer
	config    RagConfig
}

func NewRagBackfillService(providers []RagSourceBatchProvider, indexer RagIndexer, config RagConfig) *RagBackfillService {
	return &RagBackfillService{
		providers: providers,
		indexer:   indexer,
		config:    normalizeRagConfig(config),
	}
}

func (s *RagBackfillService) RunBatch(ctx context.Context, page, size int) (RagBackfillResult, error) {
	if !s.config.Enabled || !s.config.IndexingEnabled {
		return RagBackfillResult{Enabled: false}, nil
	}

	page = normalizeLimit(page, 0)
	size = normalizeLimit(size, s.config.MaxBatchSize)
	var result RagBackfillResult
	result.Enabled = true

	for _, provider := range s.providers {
		sources, hasMore, err := provider.LoadBatch(ctx, page, size)
		if err != nil {
			return RagBackfillResult{}, err
		}
		if hasMore {
			result.HasMore = true
		}
		for _, source := range sources {
			if _, err := s.indexer.Index(ctx, source); err != nil {
				result.FailedDocuments++
				continue
			}
			result.ProcessedDocuments++
		}
	}

	return result, nil
}

func (s *RagBackfillService) RunBatches(ctx context.Context, startPage, size, maxPages int) (RagBackfillRunResult, error) {
	if !s.config.Enabled || !s.config.IndexingEnabled {
		return RagBackfillRunResult{Enabled: false}, nil
	}

	startPage = normalizeLimit(startPage, 0)
	maxPages = normalizeLimit(maxPages, 100)
	var run RagBackfillRunResult
	run.Enabled = true

	for offset := 0; offset < maxPages; offset++ {
		batch, err := s.RunBatch(ctx, startPage+offset, size)
		if err != nil {
			return RagBackfillRunResult{}, err
		}
		run.ProcessedPages++
		run.ProcessedDocuments += batch.ProcessedDocuments
		run.FailedDocuments += batch.FailedDocuments
		run.HasMore = batch.HasMore
		if !batch.HasMore {
			break
		}
	}

	return run, nil
}
