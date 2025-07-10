package domain

import (
	"time"

	"gorm.io/gorm"
)

// DriverInformation 表示 driver_information 表的实体
type DriverInformation struct {
	DriverID            int            `gorm:"column:driver_id;primaryKey;autoIncrement" json:"driver_id"`
	Name                string         `gorm:"column:name" json:"name"`
	IDCardNumber        string         `gorm:"column:id_card_number" json:"id_card_number"`
	ContactNumber       string         `gorm:"column:contact_number" json:"contact_number"`
	DriverLicenseNumber string         `gorm:"column:driver_license_number" json:"driver_license_number"`
	Gender              string         `gorm:"column:gender" json:"gender"`
	Birthdate           time.Time      `gorm:"column:birthdate" json:"birthdate"`
	FirstLicenseDate    time.Time      `gorm:"column:first_license_date" json:"first_license_date"`
	AllowedVehicleType  string         `gorm:"column:allowed_vehicle_type" json:"allowed_vehicle_type"`
	IssueDate           time.Time      `gorm:"column:issue_date" json:"issue_date"`
	ExpiryDate          time.Time      `gorm:"column:expiry_date" json:"expiry_date"`
	DeletedAt           gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (DriverInformation) TableName() string {
	return "driver_information"
}
