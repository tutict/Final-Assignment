package repo

import (
	"final_assignment_front_go/project/internal/domain"

	"gorm.io/gorm"
)

// LoginLogRepo 提供 LoginLog 的数据库操作
type LoginLogRepo struct {
	db *gorm.DB
}

// NewLoginLogRepo 创建新的仓库实例
func NewLoginLogRepo(db *gorm.DB) *LoginLogRepo {
	return &LoginLogRepo{db: db}
}

// Create 创建新的 LoginLog 记录
func (r *LoginLogRepo) Create(log *domain.LoginLog) error {
	return r.db.Create(log).Error
}

// FindAll 获取所有 LoginLog 记录
func (r *LoginLogRepo) FindAll() ([]domain.LoginLog, error) {
	var logs []domain.LoginLog
	err := r.db.Find(&logs).Error
	return logs, err
}
