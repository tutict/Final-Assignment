package domain

import (
	"time"

	"gorm.io/gorm"
)

// LoginLog maps traffic.audit_login_log and emits camelCase JSON.
type LoginLog struct {
	LogID          int            `gorm:"column:log_id;primaryKey;autoIncrement" json:"logId"`
	Username       string         `gorm:"column:username" json:"username"`
	LoginTime      time.Time      `gorm:"column:login_time" json:"loginTime"`
	LogoutTime     *time.Time     `gorm:"column:logout_time" json:"logoutTime"`
	LoginResult    string         `gorm:"column:login_result" json:"loginResult"`
	FailureReason  string         `gorm:"column:failure_reason" json:"failureReason"`
	LoginIP        string         `gorm:"column:login_ip" json:"loginIp"`
	LoginIPAddress string         `gorm:"-" json:"loginIpAddress"`
	LoginLocation  string         `gorm:"column:login_location" json:"loginLocation"`
	BrowserType    string         `gorm:"column:browser_type" json:"browserType"`
	BrowserVersion string         `gorm:"column:browser_version" json:"browserVersion"`
	OSType         string         `gorm:"column:os_type" json:"osType"`
	OSVersion      string         `gorm:"column:os_version" json:"osVersion"`
	DeviceType     string         `gorm:"column:device_type" json:"deviceType"`
	UserAgent      string         `gorm:"column:user_agent" json:"userAgent"`
	SessionID      string         `gorm:"column:session_id" json:"sessionId"`
	CreatedAt      *time.Time     `gorm:"column:created_at" json:"createdAt"`
	Remarks        string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt      gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (LoginLog) TableName() string {
	return "audit_login_log"
}

func (l *LoginLog) AfterFind(tx *gorm.DB) error {
	l.LoginIPAddress = l.LoginIP
	return nil
}

func (l *LoginLog) BeforeSave(tx *gorm.DB) error {
	if l.LoginIP == "" && l.LoginIPAddress != "" {
		l.LoginIP = l.LoginIPAddress
	}
	return nil
}
