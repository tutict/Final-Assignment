package service

import (
	"context"
	"strings"
	"unicode/utf8"

	"final_assignment_backend_go/project/internal/domain"
)

type RagIndexingService struct {
	documents *RagDocumentService
	chunks    *RagChunkService
	tasks     *RagEmbeddingTaskService
	chunker   RagChunker
	config    RagConfig
}

func NewRagIndexingService(
	documents *RagDocumentService,
	chunks *RagChunkService,
	tasks *RagEmbeddingTaskService,
	chunker RagChunker,
	config RagConfig,
) *RagIndexingService {
	if chunker == nil {
		chunker = NewSimpleRagChunker(1200, 150)
	}
	return &RagIndexingService{
		documents: documents,
		chunks:    chunks,
		tasks:     tasks,
		chunker:   chunker,
		config:    normalizeRagConfig(config),
	}
}

func (s *RagIndexingService) Index(ctx context.Context, source domain.RagSourceDocument) (RagIndexingResult, error) {
	if !s.config.Enabled || !s.config.IndexingEnabled {
		return RagIndexingResult{}, nil
	}

	now := nowUTC()
	document, err := s.documents.UpsertSource(ctx, source, now)
	if err != nil {
		return RagIndexingResult{}, err
	}
	sourceChunks, err := s.chunker.Chunk(source)
	if err != nil {
		return RagIndexingResult{}, err
	}
	chunks, err := s.chunks.UpsertChunks(ctx, document, sourceChunks, now)
	if err != nil {
		return RagIndexingResult{}, err
	}
	tasks, err := s.tasks.EnsurePendingTasks(ctx, chunks, now)
	if err != nil {
		return RagIndexingResult{}, err
	}
	document, err = s.documents.MarkIndexed(ctx, document, now)
	if err != nil {
		return RagIndexingResult{}, err
	}

	return RagIndexingResult{
		Document:       document,
		Chunks:         chunks,
		EmbeddingTasks: tasks,
	}, nil
}

type SimpleRagChunker struct {
	maxRunes int
	overlap  int
}

func NewSimpleRagChunker(maxRunes, overlap int) *SimpleRagChunker {
	if maxRunes <= 0 {
		maxRunes = 1200
	}
	if overlap < 0 {
		overlap = 0
	}
	if overlap >= maxRunes {
		overlap = maxRunes / 4
	}
	return &SimpleRagChunker{maxRunes: maxRunes, overlap: overlap}
}

func (c *SimpleRagChunker) Chunk(source domain.RagSourceDocument) ([]RagSourceChunk, error) {
	normalized, err := NormalizeRagSourceDocument(source)
	if err != nil {
		return nil, err
	}
	content := strings.TrimSpace(normalized.Content)
	if content == "" {
		return []RagSourceChunk{}, nil
	}

	runes := []rune(content)
	chunks := make([]RagSourceChunk, 0, len(runes)/c.maxRunes+1)
	for start, chunkNo := 0, 0; start < len(runes); chunkNo++ {
		end := start + c.maxRunes
		if end > len(runes) {
			end = len(runes)
		}
		text := strings.TrimSpace(string(runes[start:end]))
		if text != "" {
			chunks = append(chunks, RagSourceChunk{
				ChunkNo:     chunkNo,
				Content:     text,
				ContentHash: sha256Hex(text),
				TokenCount:  roughTokenCount(text),
				CharCount:   utf8.RuneCountInString(text),
				SourceField: normalized.SourceField,
			})
		}
		if end == len(runes) {
			break
		}
		start = end - c.overlap
	}
	return chunks, nil
}

func roughTokenCount(value string) int {
	runes := utf8.RuneCountInString(value)
	if runes == 0 {
		return 0
	}
	return runes/2 + 1
}
