package repo

import (
	"final_assignment_front_go/project/internal/domain"

	"gorm.io/gorm"
)

// FineInformationRepo 提供 FineInformation 的数据库操作
type FineInformationRepo struct {
	db *gorm.DB
}

// NewFineInformationRepo 创建新的仓库实例
func NewFineInformationRepo(db *gorm.DB) *FineInformationRepo {
	return &FineInformationRepo{db: db}
}

// Create 创建新的 FineInformation 记录
func (r *FineInformationRepo) Create(fine *domain.FineInformation) error {
	return r.db.Create(fine).Error
}

// FindAll 获取所有 FineInformation 记录
func (r *FineInformationRepo) FindAll() ([]domain.FineInformation, error) {
	var fines []domain.FineInformation
	err := r.db.Find(&fines).Error
	return fines, err
}
