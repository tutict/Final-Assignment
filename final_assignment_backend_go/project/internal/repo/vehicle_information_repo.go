package repo

import (
	"final_assignment_backend_go/project/internal/domain"

	"gorm.io/gorm"
)

// VehicleInformationRepo 提供 VehicleInformation 的数据库操作
type VehicleInformationRepo struct {
	db *gorm.DB
}

// NewVehicleInformationRepo 创建新的仓库实例
func NewVehicleInformationRepo(db *gorm.DB) *VehicleInformationRepo {
	return &VehicleInformationRepo{db: db}
}

// Create 创建新的 VehicleInformation 记录
func (r *VehicleInformationRepo) Create(vehicle *domain.VehicleInformation) error {
	return r.db.Create(vehicle).Error
}

// FindAll 获取所有 VehicleInformation 记录
func (r *VehicleInformationRepo) FindAll() ([]domain.VehicleInformation, error) {
	var vehicles []domain.VehicleInformation
	err := r.db.Find(&vehicles).Error
	return vehicles, err
}

// FindByID 根据 vehicle_id 查询 VehicleInformation 记录
func (r *VehicleInformationRepo) FindByID(id int) (*domain.VehicleInformation, error) {
	var vehicle domain.VehicleInformation
	err := r.db.Where("vehicle_id = ?", id).First(&vehicle).Error
	if err != nil {
		return nil, err
	}
	return &vehicle, nil
}

// Update 更新 VehicleInformation 记录
func (r *VehicleInformationRepo) Update(vehicle *domain.VehicleInformation) error {
	return r.db.Save(vehicle).Error
}

// Delete 根据 vehicle_id 删除 VehicleInformation 记录
func (r *VehicleInformationRepo) Delete(id int) error {
	return r.db.Where("vehicle_id = ?", id).Delete(&domain.VehicleInformation{}).Error
}
