package domain

import (
	"time"

	"gorm.io/gorm"
)

// SysSetting maps the key-value traffic.sys_settings table.
type SysSetting struct {
	SettingID    int            `gorm:"column:setting_id;primaryKey;autoIncrement" json:"settingId"`
	SettingKey   string         `gorm:"column:setting_key" json:"settingKey"`
	SettingValue string         `gorm:"column:setting_value" json:"settingValue"`
	SettingType  string         `gorm:"column:setting_type" json:"settingType"`
	Category     string         `gorm:"column:category" json:"category"`
	Description  string         `gorm:"column:description" json:"description"`
	IsEncrypted  bool           `gorm:"column:is_encrypted" json:"isEncrypted"`
	IsEditable   bool           `gorm:"column:is_editable" json:"isEditable"`
	SortOrder    int            `gorm:"column:sort_order" json:"sortOrder"`
	CreatedAt    *time.Time     `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt    *time.Time     `gorm:"column:updated_at" json:"updatedAt"`
	UpdatedBy    string         `gorm:"column:updated_by" json:"updatedBy"`
	DeletedAt    gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
	Remarks      string         `gorm:"column:remarks" json:"remarks"`
}

func (SysSetting) TableName() string {
	return "sys_settings"
}

// SystemSettings is the aggregated DTO expected by the React settings page.
type SystemSettings struct {
	SettingID         int    `json:"settingId"`
	SystemName        string `json:"systemName"`
	SystemVersion     string `json:"systemVersion"`
	SystemDescription string `json:"systemDescription"`
	CopyrightInfo     string `json:"copyrightInfo"`
	StoragePath       string `json:"storagePath"`
	LoginTimeout      int    `json:"loginTimeout"`
	SessionTimeout    int    `json:"sessionTimeout"`
	DateFormat        string `json:"dateFormat"`
	PageSize          int    `json:"pageSize"`
	SMTPServer        string `json:"smtpServer"`
	EmailAccount      string `json:"emailAccount"`
	EmailPassword     string `json:"emailPassword"`
	Remarks           string `json:"remarks"`
}
