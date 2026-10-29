package repo

import (
	"context"

	"final_assignment_backend_go/project/internal/domain"

	"gorm.io/gorm"
)

// RagTreeDeletionRepo 在一个事务里删除文档、分块与嵌入任务。
//
// 库里的删除是权威动作：任务、分块、文档要么全删要么全留，
// 避免出现任务已删而分块仍在的中间状态。
type RagTreeDeletionRepo struct {
	db *gorm.DB
}

func NewRagTreeDeletionRepo(db *gorm.DB) *RagTreeDeletionRepo {
	return &RagTreeDeletionRepo{db: db}
}

// DeleteDocumentTree 删除文档及其分块、任务，返回被删除的分块 ID 与删除计数。
func (r *RagTreeDeletionRepo) DeleteDocumentTree(
	ctx context.Context,
	documentID string,
) ([]string, map[string]int64, error) {
	var (
		chunkIDs []string
		counts   map[string]int64
	)
	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var chunks []domain.RagChunk
		if err := tx.Where("document_id = ?", documentID).Order("chunk_no ASC").Find(&chunks).Error; err != nil {
			return err
		}
		chunkIDs = make([]string, 0, len(chunks))
		for _, chunk := range chunks {
			chunkIDs = append(chunkIDs, chunk.ID)
		}

		var deletedTasks int64
		for _, chunkID := range chunkIDs {
			result := tx.Where("chunk_id = ?", chunkID).Delete(&domain.RagEmbeddingTask{})
			if result.Error != nil {
				return result.Error
			}
			deletedTasks += result.RowsAffected
		}

		chunkResult := tx.Where("document_id = ?", documentID).Delete(&domain.RagChunk{})
		if chunkResult.Error != nil {
			return chunkResult.Error
		}
		documentResult := tx.Where("id = ?", documentID).Delete(&domain.RagDocument{})
		if documentResult.Error != nil {
			return documentResult.Error
		}

		counts = map[string]int64{
			"documents": documentResult.RowsAffected,
			"chunks":    chunkResult.RowsAffected,
			"tasks":     deletedTasks,
		}
		return nil
	})
	if err != nil {
		return nil, nil, err
	}
	return chunkIDs, counts, nil
}
