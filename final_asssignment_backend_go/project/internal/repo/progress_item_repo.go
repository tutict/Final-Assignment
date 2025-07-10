package repo

import (
	"final_asssignment_front_go/project/internal/domain"
	"gorm.io/gorm"
)

// ProgressItemRepo 提供 ProgressItem 的数据库操作
type ProgressItemRepo struct {
	db *gorm.DB
}

// NewProgressItemRepo 创建新的仓库实例
func NewProgressItemRepo(db *gorm.DB) *ProgressItemRepo {
	return &ProgressItemRepo{db: db}
}

// Create 创建新的 ProgressItem 记录
func (r *ProgressItemRepo) Create(item *domain.ProgressItem) error {
	return r.db.Create(item).Error
}

// FindAll 获取所有 ProgressItem 记录
func (r *ProgressItemRepo) FindAll() ([]domain.ProgressItem, error) {
	var items []domain.ProgressItem
	err := r.db.Find(&items).Error
	return items, err
}
