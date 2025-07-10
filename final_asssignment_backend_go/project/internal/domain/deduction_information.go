package domain

import (
	"time"

	"gorm.io/gorm"
)

// DeductionInformation 表示 deduction_information 表的实体
type DeductionInformation struct {
	DeductionID    int            `gorm:"column:deduction_id;primaryKey;autoIncrement" json:"deduction_id"`
	OffenseID      int            `gorm:"column:offense_id" json:"offense_id"`
	DeductedPoints int            `gorm:"column:deducted_points" json:"deducted_points"`
	DeductionTime  time.Time      `gorm:"column:deduction_time" json:"deduction_time"`
	Handler        string         `gorm:"column:handler" json:"handler"`
	Approver       string         `gorm:"column:approver" json:"approver"`
	Remarks        string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt      gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (DeductionInformation) TableName() string {
	return "deduction_information"
}
