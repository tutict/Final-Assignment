package repo

import (
	"final_asssignment_front_go/project/internal/domain"

	"gorm.io/gorm"
)

// RoleManagementRepo 提供 RoleManagement 的数据库操作
type RoleManagementRepo struct {
	db *gorm.DB
}

// NewRoleManagementRepo 创建新的仓库实例
func NewRoleManagementRepo(db *gorm.DB) *RoleManagementRepo {
	return &RoleManagementRepo{db: db}
}

// Create 创建新的 RoleManagement 记录
func (r *RoleManagementRepo) Create(role *domain.RoleManagement) error {
	return r.db.Create(role).Error
}

// FindAll 获取所有 RoleManagement 记录
func (r *RoleManagementRepo) FindAll() ([]domain.RoleManagement, error) {
	var roles []domain.RoleManagement
	err := r.db.Find(&roles).Error
	return roles, err
}
