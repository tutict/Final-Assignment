package repo

import (
	"context"
	"time"

	"final_assignment_backend_go/project/internal/domain"

	"gorm.io/gorm"
)

type RagDocumentRepo struct {
	db *gorm.DB
}

func NewRagDocumentRepo(db *gorm.DB) *RagDocumentRepo {
	return &RagDocumentRepo{db: db}
}

func (r *RagDocumentRepo) Save(ctx context.Context, document *domain.RagDocument) error {
	return r.db.WithContext(ctx).Save(document).Error
}

func (r *RagDocumentRepo) FindByID(ctx context.Context, id string) (*domain.RagDocument, error) {
	var document domain.RagDocument
	err := r.db.WithContext(ctx).Where("id = ?", id).First(&document).Error
	if err != nil {
		return nil, err
	}
	return &document, nil
}

func (r *RagDocumentRepo) List(ctx context.Context, query string, limit int) ([]domain.RagDocument, error) {
	db := r.db.WithContext(ctx).Order("updated_at DESC")
	if query != "" {
		like := "%" + query + "%"
		db = db.Where(
			"title LIKE ? OR source_table LIKE ? OR source_id LIKE ? OR acl_scope LIKE ? OR route LIKE ? OR metadata_json LIKE ?",
			like, like, like, like, like, like,
		)
	}
	var documents []domain.RagDocument
	err := db.Limit(limit).Find(&documents).Error
	return documents, err
}

func (r *RagDocumentRepo) Count(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&domain.RagDocument{}).Count(&count).Error
	return count, err
}

func (r *RagDocumentRepo) CountByStatus(ctx context.Context, status string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&domain.RagDocument{}).Where("status = ?", status).Count(&count).Error
	return count, err
}

func (r *RagDocumentRepo) DeleteByID(ctx context.Context, id string) (int64, error) {
	result := r.db.WithContext(ctx).Where("id = ?", id).Delete(&domain.RagDocument{})
	return result.RowsAffected, result.Error
}

type RagChunkRepo struct {
	db *gorm.DB
}

func NewRagChunkRepo(db *gorm.DB) *RagChunkRepo {
	return &RagChunkRepo{db: db}
}

func (r *RagChunkRepo) Save(ctx context.Context, chunk *domain.RagChunk) error {
	return r.db.WithContext(ctx).Save(chunk).Error
}

func (r *RagChunkRepo) FindByID(ctx context.Context, id string) (*domain.RagChunk, error) {
	var chunk domain.RagChunk
	err := r.db.WithContext(ctx).Where("id = ?", id).First(&chunk).Error
	if err != nil {
		return nil, err
	}
	return &chunk, nil
}

func (r *RagChunkRepo) ListByDocumentID(ctx context.Context, documentID string) ([]domain.RagChunk, error) {
	var chunks []domain.RagChunk
	err := r.db.WithContext(ctx).Where("document_id = ?", documentID).Order("chunk_no ASC").Find(&chunks).Error
	return chunks, err
}

func (r *RagChunkRepo) ListForRequeue(ctx context.Context, limit int) ([]domain.RagChunk, error) {
	var chunks []domain.RagChunk
	err := r.db.WithContext(ctx).Order("updated_at ASC").Limit(limit).Find(&chunks).Error
	return chunks, err
}

func (r *RagChunkRepo) Count(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&domain.RagChunk{}).Count(&count).Error
	return count, err
}

func (r *RagChunkRepo) ResetEmbedding(ctx context.Context, chunkID, model string, now time.Time) (int64, error) {
	result := r.db.WithContext(ctx).Model(&domain.RagChunk{}).
		Where("id = ?", chunkID).
		Updates(map[string]any{
			"status":          domain.RagChunkStatusPendingEmbedding,
			"embedding_model": model,
			"embedding_hash":  "",
			"updated_at":      now,
		})
	return result.RowsAffected, result.Error
}

func (r *RagChunkRepo) DeleteByDocumentID(ctx context.Context, documentID string) (int64, error) {
	result := r.db.WithContext(ctx).Where("document_id = ?", documentID).Delete(&domain.RagChunk{})
	return result.RowsAffected, result.Error
}

type RagEmbeddingTaskRepo struct {
	db *gorm.DB
}

func NewRagEmbeddingTaskRepo(db *gorm.DB) *RagEmbeddingTaskRepo {
	return &RagEmbeddingTaskRepo{db: db}
}

func (r *RagEmbeddingTaskRepo) Save(ctx context.Context, task *domain.RagEmbeddingTask) error {
	return r.db.WithContext(ctx).Save(task).Error
}

func (r *RagEmbeddingTaskRepo) FindByID(ctx context.Context, id string) (*domain.RagEmbeddingTask, error) {
	var task domain.RagEmbeddingTask
	err := r.db.WithContext(ctx).Where("id = ?", id).First(&task).Error
	if err != nil {
		return nil, err
	}
	return &task, nil
}

func (r *RagEmbeddingTaskRepo) ListRunnable(ctx context.Context, limit int, now time.Time) ([]domain.RagEmbeddingTask, error) {
	var tasks []domain.RagEmbeddingTask
	err := r.db.WithContext(ctx).
		Where("status IN ?", []string{domain.RagEmbeddingTaskStatusPending, domain.RagEmbeddingTaskStatusFailed}).
		Where("next_retry_at IS NULL OR next_retry_at <= ?", now).
		Order("created_at ASC").
		Limit(limit).
		Find(&tasks).Error
	return tasks, err
}

func (r *RagEmbeddingTaskRepo) CountByStatus(ctx context.Context, status string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&domain.RagEmbeddingTask{}).Where("status = ?", status).Count(&count).Error
	return count, err
}

func (r *RagEmbeddingTaskRepo) ResetByChunkID(ctx context.Context, chunkID, provider, model string, now time.Time) (int64, error) {
	result := r.db.WithContext(ctx).Model(&domain.RagEmbeddingTask{}).
		Where("chunk_id = ?", chunkID).
		Updates(map[string]any{
			"provider":      provider,
			"model":         model,
			"status":        domain.RagEmbeddingTaskStatusPending,
			"attempt_count": 0,
			"next_retry_at": nil,
			"last_error":    "",
			"updated_at":    now,
		})
	return result.RowsAffected, result.Error
}

func (r *RagEmbeddingTaskRepo) DeleteByChunkID(ctx context.Context, chunkID string) (int64, error) {
	result := r.db.WithContext(ctx).Where("chunk_id = ?", chunkID).Delete(&domain.RagEmbeddingTask{})
	return result.RowsAffected, result.Error
}
