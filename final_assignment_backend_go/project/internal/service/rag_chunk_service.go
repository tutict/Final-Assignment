package service

import (
	"context"
	"strconv"
	"time"

	"final_assignment_backend_go/project/internal/domain"
)

type RagChunkService struct {
	chunks RagChunkStore
}

func NewRagChunkService(chunks RagChunkStore) *RagChunkService {
	return &RagChunkService{chunks: chunks}
}

func (s *RagChunkService) UpsertChunk(ctx context.Context, document domain.RagDocument, chunk RagSourceChunk, now time.Time) (domain.RagChunk, error) {
	if chunk.ContentHash == "" {
		chunk.ContentHash = sha256Hex(chunk.Content)
	}
	if chunk.CharCount == 0 {
		chunk.CharCount = len([]rune(chunk.Content))
	}
	if chunk.SourceField == "" {
		chunk.SourceField = "content"
	}

	id := stableRagID("chk", document.ID, stringFromInt(chunk.ChunkNo), chunk.ContentHash)
	ragChunk, err := s.chunks.FindByID(ctx, id)
	if err != nil {
		ragChunk = &domain.RagChunk{
			ID:        id,
			CreatedAt: now,
		}
	}

	ragChunk.DocumentID = document.ID
	ragChunk.ChunkNo = chunk.ChunkNo
	ragChunk.Content = chunk.Content
	ragChunk.ContentHash = chunk.ContentHash
	ragChunk.TokenCount = chunk.TokenCount
	ragChunk.CharCount = chunk.CharCount
	ragChunk.SourceField = chunk.SourceField
	ragChunk.Status = domain.RagChunkStatusPendingEmbedding
	ragChunk.UpdatedAt = now

	if err := s.chunks.Save(ctx, ragChunk); err != nil {
		return domain.RagChunk{}, err
	}
	return *ragChunk, nil
}

func (s *RagChunkService) UpsertChunks(ctx context.Context, document domain.RagDocument, chunks []RagSourceChunk, now time.Time) ([]domain.RagChunk, error) {
	results := make([]domain.RagChunk, 0, len(chunks))
	for _, chunk := range chunks {
		result, err := s.UpsertChunk(ctx, document, chunk, now)
		if err != nil {
			return nil, err
		}
		results = append(results, result)
	}
	return results, nil
}

func stringFromInt(value int) string {
	return strconv.Itoa(value)
}
