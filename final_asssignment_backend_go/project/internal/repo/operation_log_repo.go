package repo

import (
	"final_asssignment_front_go/project/internal/domain"
	"gorm.io/gorm"
)

// OperationLogRepo 提供 OperationLog 的数据库操作
type OperationLogRepo struct {
	db *gorm.DB
}

// NewOperationLogRepo 创建新的仓库实例
func NewOperationLogRepo(db *gorm.DB) *OperationLogRepo {
	return &OperationLogRepo{db: db}
}

// Create 创建新的 OperationLog 记录
func (r *OperationLogRepo) Create(log *domain.OperationLog) error {
	return r.db.Create(log).Error
}

// FindAll 获取所有 OperationLog 记录
func (r *OperationLogRepo) FindAll() ([]domain.OperationLog, error) {
	var logs []domain.OperationLog
	err := r.db.Find(&logs).Error
	return logs, err
}
