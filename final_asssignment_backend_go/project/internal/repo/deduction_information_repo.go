package repo

import (
	"final_asssignment_front_go/project/internal/domain"

	"gorm.io/gorm"
)

// DeductionInformationRepo 提供 DeductionInformation 的数据库操作
type DeductionInformationRepo struct {
	db *gorm.DB
}

// NewDeductionInformationRepo 创建新的仓库实例
func NewDeductionInformationRepo(db *gorm.DB) *DeductionInformationRepo {
	return &DeductionInformationRepo{db: db}
}

// Create 创建新的 DeductionInformation 记录
func (r *DeductionInformationRepo) Create(deduction *domain.DeductionInformation) error {
	return r.db.Create(deduction).Error
}

// FindAll 获取所有 DeductionInformation 记录
func (r *DeductionInformationRepo) FindAll() ([]domain.DeductionInformation, error) {
	var deductions []domain.DeductionInformation
	err := r.db.Find(&deductions).Error
	return deductions, err
}
