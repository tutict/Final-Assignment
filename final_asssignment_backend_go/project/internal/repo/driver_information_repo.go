package repo

import (
	"final_asssignment_front_go/project/internal/domain"

	"gorm.io/gorm"
)

// DriverInformationRepo 提供 DriverInformation 的数据库操作
type DriverInformationRepo struct {
	db *gorm.DB
}

// NewDriverInformationRepo 创建新的仓库实例
func NewDriverInformationRepo(db *gorm.DB) *DriverInformationRepo {
	return &DriverInformationRepo{db: db}
}

// Create 创建新的 DriverInformation 记录
func (r *DriverInformationRepo) Create(driver *domain.DriverInformation) error {
	return r.db.Create(driver).Error
}

// FindAll 获取所有 DriverInformation 记录
func (r *DriverInformationRepo) FindAll() ([]domain.DriverInformation, error) {
	var drivers []domain.DriverInformation
	err := r.db.Find(&drivers).Error
	return drivers, err
}
