package repo

import (
	"final_assignment_backend_go/project/internal/domain"

	"gorm.io/gorm"
)

// UserRoleRepo 提供 UserRole 的数据库操作
type UserRoleRepo struct {
	db *gorm.DB
}

// NewUserRoleRepo 创建新的仓库实例
func NewUserRoleRepo(db *gorm.DB) *UserRoleRepo {
	return &UserRoleRepo{db: db}
}

// Create 创建新的 UserRole 记录
func (r *UserRoleRepo) Create(userRole *domain.UserRole) error {
	return r.db.Create(userRole).Error
}

// FindAll 获取所有 UserRole 记录
func (r *UserRoleRepo) FindAll() ([]domain.UserRole, error) {
	var userRoles []domain.UserRole
	err := r.db.Find(&userRoles).Error
	return userRoles, err
}
