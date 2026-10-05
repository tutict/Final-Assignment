package domain

import (
	"time"

	"gorm.io/gorm"
)

// SysRequestHistory maps the shared sys_request_history ledger and uses the
// camelCase JSON names the Flutter and React log pages already read.
type SysRequestHistory struct {
	ID             int64          `gorm:"column:id;primaryKey" json:"id"`
	IdempotencyKey string         `gorm:"column:idempotency_key" json:"idempotencyKey"`
	RequestMethod  string         `gorm:"column:request_method" json:"requestMethod"`
	RequestURL     string         `gorm:"column:request_url" json:"requestUrl"`
	RequestParams  string         `gorm:"column:request_params" json:"requestParams"`
	BusinessType   string         `gorm:"column:business_type" json:"businessType"`
	BusinessID     *int64         `gorm:"column:business_id" json:"businessId"`
	BusinessStatus string         `gorm:"column:business_status" json:"businessStatus"`
	UserID         *int64         `gorm:"column:user_id" json:"userId"`
	RequestIP      string         `gorm:"column:request_ip" json:"requestIp"`
	CreatedAt      time.Time      `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt      time.Time      `gorm:"column:updated_at" json:"updatedAt"`
	DeletedAt      gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (SysRequestHistory) TableName() string { return "sys_request_history" }
