package service

import (
	"context"
	"fmt"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
)

type RagDocumentService struct {
	documents RagDocumentStore
	chunks    RagChunkStore
	tasks     RagEmbeddingTaskStore
	config    RagConfig
}

func NewRagDocumentService(
	documents RagDocumentStore,
	chunks RagChunkStore,
	tasks RagEmbeddingTaskStore,
	config RagConfig,
) *RagDocumentService {
	return &RagDocumentService{
		documents: documents,
		chunks:    chunks,
		tasks:     tasks,
		config:    normalizeRagConfig(config),
	}
}

func (s *RagDocumentService) List(ctx context.Context, query string, limit int) ([]domain.RagDocument, error) {
	return s.documents.List(ctx, strings.TrimSpace(query), normalizeLimit(limit, 200))
}

func (s *RagDocumentService) Overview(ctx context.Context) (RagOverview, error) {
	documentCount, err := s.documents.Count(ctx)
	if err != nil {
		return RagOverview{}, err
	}
	readyDocumentCount, err := s.documents.CountByStatus(ctx, domain.RagDocumentStatusReady)
	if err != nil {
		return RagOverview{}, err
	}
	chunkCount, err := s.chunks.Count(ctx)
	if err != nil {
		return RagOverview{}, err
	}
	pendingTasks, err := s.tasks.CountByStatus(ctx, domain.RagEmbeddingTaskStatusPending)
	if err != nil {
		return RagOverview{}, err
	}
	failedTasks, err := s.tasks.CountByStatus(ctx, domain.RagEmbeddingTaskStatusFailed)
	if err != nil {
		return RagOverview{}, err
	}
	succeededTasks, err := s.tasks.CountByStatus(ctx, domain.RagEmbeddingTaskStatusSucceeded)
	if err != nil {
		return RagOverview{}, err
	}
	poisonedTasks, err := s.tasks.CountByStatus(ctx, domain.RagEmbeddingTaskStatusPoisoned)
	if err != nil {
		return RagOverview{}, err
	}

	return RagOverview{
		Enabled:                     s.config.Enabled,
		IndexingEnabled:             s.config.IndexingEnabled,
		DocumentCount:               documentCount,
		ReadyDocumentCount:          readyDocumentCount,
		ChunkCount:                  chunkCount,
		PendingEmbeddingTaskCount:   pendingTasks,
		FailedEmbeddingTaskCount:    failedTasks,
		SucceededEmbeddingTaskCount: succeededTasks,
		PoisonedEmbeddingTaskCount:  poisonedTasks,
	}, nil
}

func (s *RagDocumentService) UpsertSource(ctx context.Context, source domain.RagSourceDocument, now time.Time) (domain.RagDocument, error) {
	normalized, err := NormalizeRagSourceDocument(source)
	if err != nil {
		return domain.RagDocument{}, err
	}

	id := stableRagID("doc", normalized.SourceTable, normalized.SourceID, normalized.SourceVersion)
	document, err := s.documents.FindByID(ctx, id)
	if err != nil {
		document = &domain.RagDocument{
			ID:        id,
			CreatedAt: now,
		}
	}

	document.SourceType = normalized.SourceType
	document.SourceTable = normalized.SourceTable
	document.SourceID = normalized.SourceID
	document.SourceVersion = normalized.SourceVersion
	document.Title = normalized.Title
	document.ContentHash = sha256Hex(normalized.Content)
	document.Status = domain.RagDocumentStatusReady
	document.ACLScope = normalizeRagACLScope(normalized.ACLScope)
	document.Route = normalized.Route
	document.MetadataJSON = normalized.MetadataJSON
	document.UpdatedAt = now

	if err := s.documents.Save(ctx, document); err != nil {
		return domain.RagDocument{}, err
	}
	return *document, nil
}

func (s *RagDocumentService) MarkIndexed(ctx context.Context, document domain.RagDocument, now time.Time) (domain.RagDocument, error) {
	document.IndexedAt = &now
	document.UpdatedAt = now
	if err := s.documents.Save(ctx, &document); err != nil {
		return domain.RagDocument{}, err
	}
	return document, nil
}

func (s *RagDocumentService) DeleteDocumentTree(ctx context.Context, documentID string) (map[string]int64, error) {
	chunks, err := s.chunks.ListByDocumentID(ctx, documentID)
	if err != nil {
		return nil, err
	}

	var deletedTasks int64
	for _, chunk := range chunks {
		count, err := s.tasks.DeleteByChunkID(ctx, chunk.ID)
		if err != nil {
			return nil, err
		}
		deletedTasks += count
	}

	deletedChunks, err := s.chunks.DeleteByDocumentID(ctx, documentID)
	if err != nil {
		return nil, err
	}
	deletedDocuments, err := s.documents.DeleteByID(ctx, documentID)
	if err != nil {
		return nil, err
	}

	return map[string]int64{
		"documents": deletedDocuments,
		"chunks":    deletedChunks,
		"tasks":     deletedTasks,
	}, nil
}

func NormalizeRagSourceDocument(source domain.RagSourceDocument) (domain.RagSourceDocument, error) {
	source.SourceType = defaultIfBlank(source.SourceType, "BUSINESS")
	source.SourceTable = strings.TrimSpace(source.SourceTable)
	source.SourceID = strings.TrimSpace(source.SourceID)
	if source.SourceTable == "" {
		return domain.RagSourceDocument{}, fmt.Errorf("sourceTable must not be blank")
	}
	if source.SourceID == "" {
		return domain.RagSourceDocument{}, fmt.Errorf("sourceId must not be blank")
	}
	source.SourceVersion = defaultIfBlank(source.SourceVersion, "v1")
	source.Title = defaultIfBlank(source.Title, source.SourceTable+":"+source.SourceID)
	source.Content = defaultIfBlank(source.Content, "")
	source.ACLScope = defaultIfBlank(source.ACLScope, "PUBLIC")
	source.Route = defaultIfBlank(source.Route, "")
	source.MetadataJSON = defaultIfBlank(source.MetadataJSON, "{}")
	source.SourceField = defaultIfBlank(source.SourceField, "content")
	return source, nil
}

func normalizeRagACLScope(scope string) string {
	switch strings.ToUpper(strings.TrimSpace(scope)) {
	case "PUBLIC", "ROLE", "USER", "DEPARTMENT":
		return strings.ToUpper(strings.TrimSpace(scope))
	default:
		return "PUBLIC"
	}
}
