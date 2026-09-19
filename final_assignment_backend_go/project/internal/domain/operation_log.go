package domain

import (
	"time"

	"gorm.io/gorm"
)

// OperationLog maps traffic.audit_operation_log and emits camelCase JSON.
type OperationLog struct {
	LogID             int            `gorm:"column:log_id;primaryKey;autoIncrement" json:"logId"`
	OperationType     string         `gorm:"column:operation_type" json:"operationType"`
	OperationModule   string         `gorm:"column:operation_module" json:"operationModule"`
	OperationFunction string         `gorm:"column:operation_function" json:"operationFunction"`
	OperationContent  string         `gorm:"column:operation_content" json:"operationContent"`
	OperationTime     time.Time      `gorm:"column:operation_time" json:"operationTime"`
	UserID            *int64         `gorm:"column:user_id" json:"userId"`
	Username          string         `gorm:"column:username" json:"username"`
	RealName          string         `gorm:"column:real_name" json:"realName"`
	RequestMethod     string         `gorm:"column:request_method" json:"requestMethod"`
	RequestURL        string         `gorm:"column:request_url" json:"requestUrl"`
	RequestParams     string         `gorm:"column:request_params" json:"requestParams"`
	RequestIP         string         `gorm:"column:request_ip" json:"requestIp"`
	OperationIPAddress string        `gorm:"-" json:"operationIpAddress"`
	OperationResult   string         `gorm:"column:operation_result" json:"operationResult"`
	ResponseData      string         `gorm:"column:response_data" json:"responseData"`
	ErrorMessage      string         `gorm:"column:error_message" json:"errorMessage"`
	ExecutionTime     *int           `gorm:"column:execution_time" json:"executionTime"`
	CreatedAt         *time.Time     `gorm:"column:created_at" json:"createdAt"`
	Remarks           string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt         gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (OperationLog) TableName() string {
	return "audit_operation_log"
}

func (l *OperationLog) AfterFind(tx *gorm.DB) error {
	l.OperationIPAddress = l.RequestIP
	return nil
}
