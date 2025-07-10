package domain

import (
	"time"

	"gorm.io/gorm"
)

// AppealManagement 表示 appeal_management 表的实体
type AppealManagement struct {
	AppealID      int            `gorm:"column:appeal_id;primaryKey;autoIncrement" json:"appeal_id"`
	OffenseID     int            `gorm:"column:offense_id" json:"offenseId"`
	AppellantName string         `gorm:"column:appellant_name" json:"appellant_name"`
	IDCardNumber  string         `gorm:"column:id_card_number" json:"id_card_number"`
	ContactNumber string         `gorm:"column:contact_number" json:"contact_number"`
	AppealReason  string         `gorm:"column:appeal_reason" json:"appeal_reason"`
	AppealTime    time.Time      `gorm:"column:appeal_time" json:"appeal_time"`
	ProcessStatus string         `gorm:"column:process_status" json:"process_status"`
	ProcessResult string         `gorm:"column:process_result" json:"process_result"`
	DeletedAt     gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (AppealManagement) TableName() string {
	return "appeal_management"
}
