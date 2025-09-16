package repo

import (
	"final_asssignment_front_go/project/internal/domain"

	"gorm.io/gorm"
)

// AppealManagementRepo 提供 AppealManagement 的数据库操作
type AppealManagementRepo struct {
	db *gorm.DB
}

// NewAppealManagementRepo 创建新的仓库实例
func NewAppealManagementRepo(db *gorm.DB) *AppealManagementRepo {
	return &AppealManagementRepo{db: db}
}

// Create 创建新的 AppealManagement 记录
func (r *AppealManagementRepo) Create(appeal *domain.AppealManagement) error {
	return r.db.Create(appeal).Error
}

// FindAll 获取所有 AppealManagement 记录
func (r *AppealManagementRepo) FindAll() ([]domain.AppealManagement, error) {
	var appeals []domain.AppealManagement
	err := r.db.Find(&appeals).Error
	return appeals, err
}
