package rag

import (
	"context"
	"errors"
	"testing"

	"final_assignment_backend_go/project/internal/domain"
)

type memoryRagTreeDeletionStore struct {
	documents *memoryRagDocumentStore
	chunks    *memoryRagChunkStore
	tasks     *memoryRagEmbeddingTaskStore
	failure   error
}

func newMemoryRagTreeDeletionStore(
	documents *memoryRagDocumentStore,
	chunks *memoryRagChunkStore,
	tasks *memoryRagEmbeddingTaskStore,
) *memoryRagTreeDeletionStore {
	return &memoryRagTreeDeletionStore{documents: documents, chunks: chunks, tasks: tasks}
}

func (s *memoryRagTreeDeletionStore) DeleteDocumentTree(
	ctx context.Context,
	documentID string,
) ([]string, map[string]int64, error) {
	if s.failure != nil {
		return nil, nil, s.failure
	}
	chunks, err := s.chunks.ListByDocumentID(ctx, documentID)
	if err != nil {
		return nil, nil, err
	}
	chunkIDs := make([]string, 0, len(chunks))
	var deletedTasks int64
	for _, chunk := range chunks {
		chunkIDs = append(chunkIDs, chunk.ID)
		for id, task := range s.tasks.items {
			if task.ChunkID == chunk.ID {
				delete(s.tasks.items, id)
				deletedTasks++
			}
		}
	}
	var deletedChunks int64
	for id, chunk := range s.chunks.items {
		if chunk.DocumentID == documentID {
			delete(s.chunks.items, id)
			deletedChunks++
		}
	}
	var deletedDocuments int64
	if _, ok := s.documents.items[documentID]; ok {
		delete(s.documents.items, documentID)
		deletedDocuments = 1
	}
	return chunkIDs, map[string]int64{
		"documents": deletedDocuments,
		"chunks":    deletedChunks,
		"tasks":     deletedTasks,
	}, nil
}

type memoryRagVectorDeleter struct {
	deleted []string
	failure error
}

func (d *memoryRagVectorDeleter) DeleteChunk(_ context.Context, chunkID string) error {
	if d.failure != nil {
		return d.failure
	}
	d.deleted = append(d.deleted, chunkID)
	return nil
}

func TestRagDocumentServiceDeletesIndexDocumentsWithDocument(t *testing.T) {
	ctx := context.Background()
	documents := newMemoryRagDocumentStore()
	chunks := newMemoryRagChunkStore()
	tasks := newMemoryRagEmbeddingTaskStore()
	now := nowUTC()

	if err := documents.Save(ctx, &domain.RagDocument{
		ID:        "doc-1",
		Status:    domain.RagDocumentStatusReady,
		CreatedAt: now,
		UpdatedAt: now,
	}); err != nil {
		t.Fatalf("save document: %v", err)
	}
	for _, chunkID := range []string{"chunk-1", "chunk-2"} {
		if err := chunks.Save(ctx, &domain.RagChunk{
			ID:         chunkID,
			DocumentID: "doc-1",
			Status:     domain.RagChunkStatusEmbedded,
			CreatedAt:  now,
			UpdatedAt:  now,
		}); err != nil {
			t.Fatalf("save chunk: %v", err)
		}
		if err := tasks.Save(ctx, &domain.RagEmbeddingTask{
			ID:         "task-" + chunkID,
			ChunkID:    chunkID,
			Status:     domain.RagEmbeddingTaskStatusSucceeded,
			CreatedAt:  now,
			UpdatedAt:  now,
		}); err != nil {
			t.Fatalf("save task: %v", err)
		}
	}

	deleter := &memoryRagVectorDeleter{}
	service := NewRagDocumentService(
		documents,
		chunks,
		tasks,
		newMemoryRagTreeDeletionStore(documents, chunks, tasks),
		DefaultRagConfig(),
	).WithVectorDeletion(deleter)

	counts, err := service.DeleteDocumentTree(ctx, "doc-1")
	if err != nil {
		t.Fatalf("DeleteDocumentTree() error = %v", err)
	}
	if counts["documents"] != 1 || counts["chunks"] != 2 || counts["tasks"] != 2 {
		t.Fatalf("unexpected deletion counts: %+v", counts)
	}
	if len(deleter.deleted) != 2 {
		t.Fatalf("index deletions = %v, want 2 chunks", deleter.deleted)
	}
	for _, chunkID := range []string{"chunk-1", "chunk-2"} {
		found := false
		for _, deleted := range deleter.deleted {
			if deleted == chunkID {
				found = true
				break
			}
		}
		if !found {
			t.Fatalf("chunk %s was not removed from the index: %v", chunkID, deleter.deleted)
		}
	}
	if _, err := documents.FindByID(ctx, "doc-1"); !errAsNotFound(err) {
		t.Fatalf("document was not deleted: %v", err)
	}
}

func TestRagDocumentServiceKeepsDeletionWhenIndexCleanupFails(t *testing.T) {
	ctx := context.Background()
	documents := newMemoryRagDocumentStore()
	chunks := newMemoryRagChunkStore()
	tasks := newMemoryRagEmbeddingTaskStore()
	now := nowUTC()

	if err := documents.Save(ctx, &domain.RagDocument{
		ID:        "doc-1",
		Status:    domain.RagDocumentStatusReady,
		CreatedAt: now,
		UpdatedAt: now,
	}); err != nil {
		t.Fatalf("save document: %v", err)
	}
	if err := chunks.Save(ctx, &domain.RagChunk{
		ID:         "chunk-1",
		DocumentID: "doc-1",
		Status:     domain.RagChunkStatusEmbedded,
		CreatedAt:  now,
		UpdatedAt:  now,
	}); err != nil {
		t.Fatalf("save chunk: %v", err)
	}

	deleter := &memoryRagVectorDeleter{failure: errors.New("elasticsearch unavailable")}
	service := NewRagDocumentService(
		documents,
		chunks,
		tasks,
		newMemoryRagTreeDeletionStore(documents, chunks, tasks),
		DefaultRagConfig(),
	).WithVectorDeletion(deleter)

	counts, err := service.DeleteDocumentTree(ctx, "doc-1")
	if err != nil {
		t.Fatalf("DeleteDocumentTree() error = %v", err)
	}
	if counts["documents"] != 1 || counts["chunks"] != 1 {
		t.Fatalf("unexpected deletion counts: %+v", counts)
	}
	if _, err := documents.FindByID(ctx, "doc-1"); !errAsNotFound(err) {
		t.Fatalf("document was not deleted: %v", err)
	}
}

func TestRagDocumentServiceRejectsBlankDocumentID(t *testing.T) {
	documents := newMemoryRagDocumentStore()
	chunks := newMemoryRagChunkStore()
	tasks := newMemoryRagEmbeddingTaskStore()
	service := NewRagDocumentService(
		documents,
		chunks,
		tasks,
		newMemoryRagTreeDeletionStore(documents, chunks, tasks),
		DefaultRagConfig(),
	)

	if _, err := service.DeleteDocumentTree(context.Background(), "   "); err == nil {
		t.Fatal("expected a blank document id to be rejected")
	}
}
