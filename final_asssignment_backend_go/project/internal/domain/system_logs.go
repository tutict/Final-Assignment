package domain

import (
	"time"

	"gorm.io/gorm"
)

// SystemLogs 表示 system_logs 表的实体
type SystemLogs struct {
	LogID              int            `gorm:"column:log_id;primaryKey;autoIncrement" json:"log_id"`
	LogType            string         `gorm:"column:log_type" json:"log_type"`
	LogContent         string         `gorm:"column:log_content" json:"log_content"`
	OperationTime      time.Time      `gorm:"column:operation_time" json:"operation_time"`
	OperationUser      string         `gorm:"column:operation_user" json:"operation_user"`
	OperationIPAddress string         `gorm:"column:operation_ip_address" json:"operation_ip_address"`
	Remarks            string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt          gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (SystemLogs) TableName() string {
	return "system_logs"
}
