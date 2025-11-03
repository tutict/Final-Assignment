package domain

import (
	"time"

	"gorm.io/gorm"
)

// ProgressItem 表示 progress_items 表的实体
type ProgressItem struct {
	ID         int            `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	Title      string         `gorm:"column:title" json:"title"`
	Status     string         `gorm:"column:status" json:"status"` // "Pending", "Processing", "Completed", "Archived"
	SubmitTime time.Time      `gorm:"column:submit_time" json:"submit_time"`
	Details    string         `gorm:"column:details" json:"details"`
	Username   string         `gorm:"column:username" json:"username"`
	DeletedAt  gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (ProgressItem) TableName() string {
	return "progress_items"
}
