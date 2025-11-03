package repo

import (
	"final_assignment_front_go/project/internal/domain"

	"gorm.io/gorm"
)

// OffenseDetailsRepo 提供 OffenseDetails 的数据库操作
type OffenseDetailsRepo struct {
	db *gorm.DB
}

// NewOffenseDetailsRepo 创建新的仓库实例
func NewOffenseDetailsRepo(db *gorm.DB) *OffenseDetailsRepo {
	return &OffenseDetailsRepo{db: db}
}

// Create 创建新的 OffenseDetails 记录
func (r *OffenseDetailsRepo) Create(offense *domain.OffenseDetails) error {
	return r.db.Create(offense).Error
}

// FindAll 获取所有 OffenseDetails 记录
func (r *OffenseDetailsRepo) FindAll() ([]domain.OffenseDetails, error) {
	var offenses []domain.OffenseDetails
	err := r.db.Find(&offenses).Error
	return offenses, err
}
