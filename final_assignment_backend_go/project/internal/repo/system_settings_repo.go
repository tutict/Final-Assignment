package repo

import (
	"final_assignment_backend_go/project/internal/domain"

	"gorm.io/gorm"
)

// SystemSettingsRepo 提供 SystemSettings 的数据库操作
type SystemSettingsRepo struct {
	db *gorm.DB
}

// NewSystemSettingsRepo 创建新的仓库实例
func NewSystemSettingsRepo(db *gorm.DB) *SystemSettingsRepo {
	return &SystemSettingsRepo{db: db}
}

// Create 创建新的 SystemSettings 记录
func (r *SystemSettingsRepo) Create(settings *domain.SystemSettings) error {
	return r.db.Create(settings).Error
}

// FindAll 获取所有 SystemSettings 记录
func (r *SystemSettingsRepo) FindAll() ([]domain.SystemSettings, error) {
	var settings []domain.SystemSettings
	err := r.db.Find(&settings).Error
	return settings, err
}
