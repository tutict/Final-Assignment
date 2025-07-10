package domain

import (
	"time"

	"gorm.io/gorm"
)

// FineInformation 表示 fine_information 表的实体
type FineInformation struct {
	FineID        int            `gorm:"column:fine_id;primaryKey;autoIncrement" json:"fine_id"`
	OffenseID     int            `gorm:"column:offense_id" json:"offense_id"`
	FineAmount    float64        `gorm:"column:fine_amount" json:"fine_amount"`
	FineTime      time.Time      `gorm:"column:fine_time" json:"fine_time"`
	Payee         string         `gorm:"column:payee" json:"payee"`
	AccountNumber string         `gorm:"column:account_number" json:"account_number"`
	Bank          string         `gorm:"column:bank" json:"bank"`
	ReceiptNumber string         `gorm:"column:receipt_number" json:"receipt_number"`
	Remarks       string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt     gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (FineInformation) TableName() string {
	return "fine_information"
}
