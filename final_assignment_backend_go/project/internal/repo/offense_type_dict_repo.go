package repo

import (
	"final_assignment_backend_go/project/internal/domain"

	"gorm.io/gorm"
)

// OffenseTypeDictRepo 提供 OffenseTypeDict 的数据库操作
type OffenseTypeDictRepo struct {
	db *gorm.DB
}

// NewOffenseTypeDictRepo 创建新的仓库实例
func NewOffenseTypeDictRepo(db *gorm.DB) *OffenseTypeDictRepo {
	return &OffenseTypeDictRepo{db: db}
}

// Create 创建新的 OffenseTypeDict 记录
func (r *OffenseTypeDictRepo) Create(dict *domain.OffenseTypeDict) error {
	return r.db.Create(dict).Error
}

// FindAll 获取所有 OffenseTypeDict 记录
func (r *OffenseTypeDictRepo) FindAll() ([]domain.OffenseTypeDict, error) {
	var dicts []domain.OffenseTypeDict
	err := r.db.Find(&dicts).Error
	return dicts, err
}
