package domain

import (
	"time"

	"gorm.io/gorm"
)

// OperationLog 表示 operation_log 表的实体
type OperationLog struct {
	LogID              int            `gorm:"column:log_id;primaryKey;autoIncrement" json:"log_id"`
	UserID             int            `gorm:"column:user_id" json:"user_id"`
	OperationTime      time.Time      `gorm:"column:operation_time" json:"operation_time"`
	OperationIPAddress string         `gorm:"column:operation_ip_address" json:"operation_ip_address"`
	OperationContent   string         `gorm:"column:operation_content" json:"operation_content"`
	OperationResult    string         `gorm:"column:operation_result" json:"operation_result"`
	Remarks            string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt          gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (OperationLog) TableName() string {
	return "operation_log"
}
