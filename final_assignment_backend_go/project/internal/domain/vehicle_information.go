package domain

import (
	"time"

	"gorm.io/gorm"
)

// VehicleInformation 表示 vehicle_information 表的实体
type VehicleInformation struct {
	VehicleID             int            `gorm:"column:vehicle_id;primaryKey;autoIncrement" json:"vehicle_id"`
	LicensePlate          string         `gorm:"column:license_plate" json:"license_plate"`
	VehicleType           string         `gorm:"column:vehicle_type" json:"vehicle_type"`
	OwnerName             string         `gorm:"column:owner_name" json:"owner_name"`
	IDCardNumber          string         `gorm:"column:id_card_number" json:"id_card_number"`
	ContactNumber         string         `gorm:"column:contact_number" json:"contact_number"`
	EngineNumber          string         `gorm:"column:engine_number" json:"engine_number"`
	FrameNumber           string         `gorm:"column:frame_number" json:"frame_number"`
	VehicleColor          string         `gorm:"column:vehicle_color" json:"vehicle_color"`
	FirstRegistrationDate time.Time      `gorm:"column:first_registration_date" json:"first_registration_date"`
	CurrentStatus         string         `gorm:"column:current_status" json:"current_status"`
	DeletedAt             gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (VehicleInformation) TableName() string {
	return "vehicle_information"
}
