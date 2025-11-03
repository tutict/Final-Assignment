package repo

import (
	"final_assignment_front_go/project/internal/domain"

	"gorm.io/gorm"
)

// OffenseInformationRepo 提供 OffenseInformation 的数据库操作
type OffenseInformationRepo struct {
	db *gorm.DB
}

// NewOffenseInformationRepo 创建新的仓库实例
func NewOffenseInformationRepo(db *gorm.DB) *OffenseInformationRepo {
	return &OffenseInformationRepo{db: db}
}

// Create 创建新的 OffenseInformation 记录
func (r *OffenseInformationRepo) Create(offense *domain.OffenseInformation) error {
	return r.db.Create(offense).Error
}

// FindAll 获取所有 OffenseInformation 记录
func (r *OffenseInformationRepo) FindAll() ([]domain.OffenseInformation, error) {
	var offenses []domain.OffenseInformation
	err := r.db.Find(&offenses).Error
	return offenses, err
}
