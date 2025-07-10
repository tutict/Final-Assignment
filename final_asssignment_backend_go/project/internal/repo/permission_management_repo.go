package repo

import (
	"final_asssignment_front_go/project/internal/domain"
	"gorm.io/gorm"
)

// PermissionManagementRepo 提供 PermissionManagement 的数据库操作
type PermissionManagementRepo struct {
	db *gorm.DB
}

// NewPermissionManagementRepo 创建新的仓库实例
func NewPermissionManagementRepo(db *gorm.DB) *PermissionManagementRepo {
	return &PermissionManagementRepo{db: db}
}

// Create 创建新的 PermissionManagement 记录
func (r *PermissionManagementRepo) Create(permission *domain.PermissionManagement) error {
	return r.db.Create(permission).Error
}

// FindAll 获取所有 PermissionManagement 记录
func (r *PermissionManagementRepo) FindAll() ([]domain.PermissionManagement, error) {
	var permissions []domain.PermissionManagement
	err := r.db.Find(&permissions).Error
	return permissions, err
}
