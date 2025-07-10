package domain

import (
	"time"

	"gorm.io/gorm"
)

// LoginLog 表示 login_log 表的实体
type LoginLog struct {
	LogID          int            `gorm:"column:log_id;primaryKey;autoIncrement" json:"log_id"`
	Username       string         `gorm:"column:username" json:"username"`
	LoginIPAddress string         `gorm:"column:login_ip_address" json:"login_ip_address"`
	LoginTime      time.Time      `gorm:"column:login_time" json:"login_time"`
	LoginResult    string         `gorm:"column:login_result" json:"login_result"`
	BrowserType    string         `gorm:"column:browser_type" json:"browser_type"`
	OSVersion      string         `gorm:"column:os_version" json:"os_version"`
	Remarks        string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt      gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (LoginLog) TableName() string {
	return "login_log"
}
