package domain

import (
	"time"

	"gorm.io/gorm"
)

// RequestHistory 表示 request_history 表的实体
type RequestHistory struct {
	ID             int64          `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	IdempotentKey  string         `gorm:"column:idempotency_key" json:"idempotency_key"`
	CreateTime     time.Time      `gorm:"column:create_time" json:"create_time"`
	BusinessStatus string         `gorm:"column:business_status" json:"business_status"`
	BusinessID     int64          `gorm:"column:business_id" json:"business_id"`
	DeletedAt      gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (RequestHistory) TableName() string {
	return "request_history"
}
