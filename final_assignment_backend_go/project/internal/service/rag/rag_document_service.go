package rag

import (
	"context"
	"fmt"
	"sort"
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

type RagDocumentDetail struct {
	Document domain.RagDocument `json:"document"`
	Content  string             `json:"content"`
	Chunks   []RagChunkView     `json:"chunks"`
}

type RagChunkView struct {
	ID              string `json:"id"`
	ChunkNo         int    `json:"chunkNo"`
	Content         string `json:"content"`
	Status          string `json:"status"`
	CharCount       int    `json:"charCount"`
	EmbeddingStatus string `json:"embeddingStatus"`
	LastError       string `json:"lastError"`
}

type RagPreviewHit struct {
	DocumentID string  `json:"documentId"`
	Title      string  `json:"title"`
	Snippet    string  `json:"snippet"`
	Score      float64 `json:"score"`
	Route      string  `json:"route"`
	ACLScope   string  `json:"aclScope"`
	SourceType string  `json:"sourceType"`
}

func (s *RagDocumentService) GetDetail(ctx context.Context, documentID string) (RagDocumentDetail, error) {
	document, err := s.documents.FindByID(ctx, documentID)
	if err != nil {
		return RagDocumentDetail{}, err
	}
	chunks, err := s.chunks.ListByDocumentID(ctx, documentID)
	if err != nil {
		return RagDocumentDetail{}, err
	}
	chunkIDs := make([]string, 0, len(chunks))
	for _, chunk := range chunks {
		chunkIDs = append(chunkIDs, chunk.ID)
	}
	tasks, err := s.tasks.ListByChunkIDs(ctx, chunkIDs)
	if err != nil {
		return RagDocumentDetail{}, err
	}
	latest := map[string]domain.RagEmbeddingTask{}
	for _, task := range tasks {
		chosen, ok := latest[task.ChunkID]
		if !ok || task.UpdatedAt.After(chosen.UpdatedAt) {
			latest[task.ChunkID] = task
		}
	}
	views := make([]RagChunkView, 0, len(chunks))
	for _, chunk := range chunks {
		view := RagChunkView{
			ID:        chunk.ID,
			ChunkNo:   chunk.ChunkNo,
			Content:   chunk.Content,
			Status:    chunk.Status,
			CharCount: chunk.CharCount,
		}
		if task, ok := latest[chunk.ID]; ok {
			view.EmbeddingStatus = task.Status
			view.LastError = task.LastError
		}
		views = append(views, view)
	}
	return RagDocumentDetail{
		Document: *document,
		Content:  stitchRagContent(chunks),
		Chunks:   views,
	}, nil
}

func (s *RagDocumentService) Preview(ctx context.Context, query, asRole string, topK int) ([]RagPreviewHit, error) {
	query = strings.TrimSpace(query)
	if query == "" {
		return nil, fmt.Errorf("query must not be blank")
	}
	if topK <= 0 {
		topK = 8
	}
	if topK > 20 {
		topK = 20
	}
	role := normalizePreviewRole(asRole)
	documents, err := s.documents.List(ctx, "", 500)
	if err != nil {
		return nil, err
	}
	allowed := map[string]domain.RagDocument{}
	ids := make([]string, 0)
	for _, document := range documents {
		if !isKnowledgeDocument(document) {
			continue
		}
		if !previewAllows(role, document.ACLScope) {
			continue
		}
		allowed[document.ID] = document
		ids = append(ids, document.ID)
	}
	if len(ids) == 0 {
		return []RagPreviewHit{}, nil
	}
	hits := make([]RagPreviewHit, 0)
	needle := strings.ToLower(query)
	for _, documentID := range ids {
		chunks, err := s.chunks.ListByDocumentID(ctx, documentID)
		if err != nil {
			return nil, err
		}
		document := allowed[documentID]
		for _, chunk := range chunks {
			contentHit := strings.Contains(strings.ToLower(chunk.Content), needle)
			titleHit := strings.Contains(strings.ToLower(document.Title), needle)
			if !contentHit && !titleHit {
				continue
			}
			score := keywordScore(query, document.Title, chunk.Content)
			if score <= 0 {
				continue
			}
			hits = append(hits, RagPreviewHit{
				DocumentID: document.ID,
				Title:      document.Title,
				Snippet:    ragSnippet(chunk.Content, 180),
				Score:      score,
				Route:      document.Route,
				ACLScope:   defaultIfBlank(document.ACLScope, "PUBLIC"),
				SourceType: document.SourceType,
			})
		}
	}
	sort.Slice(hits, func(i, j int) bool { return hits[i].Score > hits[j].Score })
	if len(hits) > topK {
		hits = hits[:topK]
	}
	return hits, nil
}

func stitchRagContent(chunks []domain.RagChunk) string {
	text := ""
	for _, chunk := range chunks {
		content := chunk.Content
		if text == "" {
			text = content
			continue
		}
		overlap := longestOverlap(text, content)
		text += content[overlap:]
	}
	return text
}

func normalizePreviewRole(asRole string) string {
	normalized := strings.ToUpper(strings.TrimSpace(asRole))
	if normalized == "DRIVER" {
		return "USER"
	}
	switch normalized {
	case "USER", "ADMIN", "SUPER_ADMIN":
		return normalized
	default:
		return "USER"
	}
}

func isKnowledgeDocument(document domain.RagDocument) bool {
	sourceType := strings.ToUpper(strings.TrimSpace(document.SourceType))
	return sourceType == "MANUAL" || sourceType == "UPLOAD"
}

func previewAllows(asRole, aclScope string) bool {
	role := normalizePreviewRole(asRole)
	scope := strings.ToUpper(strings.TrimSpace(aclScope))
	if scope == "" {
		scope = "PUBLIC"
	}
	switch scope {
	case "PUBLIC":
		return true
	case "ROLE", "DEPARTMENT":
		return role == "ADMIN" || role == "SUPER_ADMIN"
	case "USER":
		return role == "USER" || role == "SUPER_ADMIN"
	default:
		return role == "SUPER_ADMIN"
	}
}

func keywordScore(query, title, content string) float64 {
	needle := strings.ToLower(strings.TrimSpace(query))
	if needle == "" {
		return 0
	}
	score := 0.0
	if strings.Contains(strings.ToLower(title), needle) {
		score += 2
	}
	body := strings.ToLower(content)
	from := 0
	hits := 0
	for hits < 20 {
		index := strings.Index(body[from:], needle)
		if index < 0 {
			break
		}
		hits++
		from += index + len(needle)
		if from >= len(body) {
			break
		}
	}
	if extra := float64(hits) * 0.5; extra > 3 {
		score += 3
	} else {
		score += extra
	}
	return score
}

func ragSnippet(content string, maxChars int) string {
	normalized := strings.Join(strings.Fields(content), " ")
	if maxChars < 40 {
		maxChars = 40
	}
	runes := []rune(normalized)
	if len(runes) <= maxChars {
		return normalized
	}
	return string(runes[:maxChars]) + "..."
}

func longestOverlap(left, right string) int {
	if left == "" || right == "" {
		return 0
	}
	max := len(left)
	if len(right) < max {
		max = len(right)
	}
	for size := max; size > 0; size-- {
		if strings.HasSuffix(left, right[:size]) {
			return size
		}
	}
	return 0
}
