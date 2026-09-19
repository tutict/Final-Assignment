package domain

import (
	"time"

	"gorm.io/gorm"
)

// SystemLogs is served from audit_operation_log because traffic no longer
// has a dedicated system_logs table.
type SystemLogs struct {
	LogID              int            `gorm:"column:log_id;primaryKey;autoIncrement" json:"logId"`
	LogType            string         `gorm:"column:operation_type" json:"logType"`
	LogContent         string         `gorm:"column:operation_content" json:"logContent"`
	OperationTime      time.Time      `gorm:"column:operation_time" json:"operationTime"`
	OperationUser      string         `gorm:"column:username" json:"operationUser"`
	OperationIPAddress string         `gorm:"column:request_ip" json:"operationIpAddress"`
	Remarks            string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt          gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (SystemLogs) TableName() string {
	return "audit_operation_log"
}
