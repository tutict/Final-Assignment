package domain

import (
	"gorm.io/gorm"
)

// SystemSettings 表示 system_settings 表的实体
type SystemSettings struct {
	SystemName        string         `gorm:"column:system_name;primaryKey" json:"system_name"`
	SystemVersion     string         `gorm:"column:system_version" json:"system_version"`
	SystemDescription string         `gorm:"column:system_description" json:"system_description"`
	CopyrightInfo     string         `gorm:"column:copyright_info" json:"copyright_info"`
	StoragePath       string         `gorm:"column:storage_path" json:"storage_path"`
	LoginTimeout      int            `gorm:"column:login_timeout" json:"login_timeout"`
	SessionTimeout    int            `gorm:"column:session_timeout" json:"session_timeout"`
	DateFormat        string         `gorm:"column:date_format" json:"date_format"`
	PageSize          int            `gorm:"column:page_size" json:"page_size"`
	SMTPServer        string         `gorm:"column:smtp_server" json:"smtp_server"`
	EmailAccount      string         `gorm:"column:email_account" json:"email_account"`
	EmailPassword     string         `gorm:"column:email_password" json:"email_password"`
	Remarks           string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt         gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (SystemSettings) TableName() string {
	return "system_settings"
}
