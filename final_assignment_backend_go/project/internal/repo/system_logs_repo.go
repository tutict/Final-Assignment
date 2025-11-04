package repo

import (
	"final_assignment_backend_go/project/internal/domain"

	"gorm.io/gorm"
)

// SystemLogsRepo 提供 SystemLogs 的数据库操作
type SystemLogsRepo struct {
	db *gorm.DB
}

// NewSystemLogsRepo 创建新的仓库实例
func NewSystemLogsRepo(db *gorm.DB) *SystemLogsRepo {
	return &SystemLogsRepo{db: db}
}

// Create 创建新的 SystemLogs 记录
func (r *SystemLogsRepo) Create(log *domain.SystemLogs) error {
	return r.db.Create(log).Error
}

// FindAll 获取所有 SystemLogs 记录
func (r *SystemLogsRepo) FindAll() ([]domain.SystemLogs, error) {
	var logs []domain.SystemLogs
	err := r.db.Find(&logs).Error
	return logs, err
}
