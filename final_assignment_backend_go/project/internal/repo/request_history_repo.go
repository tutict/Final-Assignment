package repo

import (
	"final_assignment_front_go/project/internal/domain"

	"gorm.io/gorm"
)

// RequestHistoryRepo 提供 RequestHistory 的数据库操作
type RequestHistoryRepo struct {
	db *gorm.DB
}

// NewRequestHistoryRepo 创建新的仓库实例
func NewRequestHistoryRepo(db *gorm.DB) *RequestHistoryRepo {
	return &RequestHistoryRepo{db: db}
}

// Create 创建新的 RequestHistory 记录
func (r *RequestHistoryRepo) Create(history *domain.RequestHistory) error {
	return r.db.Create(history).Error
}

// FindAll 获取所有 RequestHistory 记录
func (r *RequestHistoryRepo) FindAll() ([]domain.RequestHistory, error) {
	var histories []domain.RequestHistory
	err := r.db.Find(&histories).Error
	return histories, err
}
