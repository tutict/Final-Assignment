package domain

import (
	"time"

	"gorm.io/gorm"
)

// OffenseDetails 表示 offense_details 表的实体
type OffenseDetails struct {
	OffenseID          int            `gorm:"column:offense_id;primaryKey" json:"offense_id"`
	OffenseTime        time.Time      `gorm:"column:offense_time" json:"offense_time"`
	OffenseLocation    string         `gorm:"column:offense_location" json:"offense_location"`
	OffenseType        string         `gorm:"column:offense_type" json:"offense_type"`
	OffenseCode        string         `gorm:"column:offense_code" json:"offense_code"`
	DriverName         string         `gorm:"column:driver_name" json:"driver_name"`
	DriverIDCardNumber string         `gorm:"column:driver_id_card_number" json:"driver_id_card_number"`
	LicensePlate       string         `gorm:"column:license_plate" json:"license_plate"`
	VehicleType        string         `gorm:"column:vehicle_type" json:"vehicle_type"`
	OwnerName          string         `gorm:"column:owner_name" json:"owner_name"`
	DeletedAt          gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (OffenseDetails) TableName() string {
	return "offense_details"
}
