package repo

import (
	"final_assignment_front_go/project/internal/domain"

	"gorm.io/gorm"
)

// UserManagementRepo 提供 UserManagement 的数据库操作
type UserManagementRepo struct {
	db *gorm.DB
}

// NewUserManagementRepo 创建新的仓库实例
func NewUserManagementRepo(db *gorm.DB) *UserManagementRepo {
	return &UserManagementRepo{db: db}
}

// Create 创建新的 UserManagement 记录
func (r *UserManagementRepo) Create(user *domain.UserManagement) error {
	return r.db.Create(user).Error
}

// FindAll 获取所有 UserManagement 记录
func (r *UserManagementRepo) FindAll() ([]domain.UserManagement, error) {
	var users []domain.UserManagement
	err := r.db.Find(&users).Error
	return users, err
}
