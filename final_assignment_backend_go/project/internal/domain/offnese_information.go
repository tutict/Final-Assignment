package domain

import (
	"time"

	"gorm.io/gorm"
)

// OffenseInformation 表示 offense_information 表的实体
type OffenseInformation struct {
	OffenseID       int            `gorm:"column:offense_id;primaryKey;autoIncrement" json:"offense_id"`
	OffenseTime     time.Time      `gorm:"column:offense_time" json:"offense_time"`
	OffenseLocation string         `gorm:"column:offense_location" json:"offense_location"`
	LicensePlate    string         `gorm:"column:license_plate" json:"license_plate"`
	DriverName      string         `gorm:"column:driver_name" json:"driver_name"`
	OffenseType     string         `gorm:"column:offense_type" json:"offense_type"`
	OffenseCode     string         `gorm:"column:offense_code" json:"offense_code"`
	FineAmount      float64        `gorm:"column:fine_amount" json:"fine_amount"`
	DeductedPoints  int            `gorm:"column:deducted_points" json:"deducted_points"`
	ProcessStatus   string         `gorm:"column:process_status" json:"process_status"`
	ProcessResult   string         `gorm:"column:process_result" json:"process_result"`
	DriverID        int            `gorm:"column:driver_id" json:"driver_id"`
	VehicleID       int            `gorm:"column:vehicle_id" json:"vehicle_id"`
	DeletedAt       gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (OffenseInformation) TableName() string {
	return "offense_information"
}
