package domain

import (
	"time"

	"gorm.io/gorm"
)

// BackupRestore maps traffic.sys_backup_restore and emits camelCase JSON.
type BackupRestore struct {
	BackupID         int            `gorm:"column:backup_id;primaryKey;autoIncrement" json:"backupId"`
	BackupType       string         `gorm:"column:backup_type" json:"backupType"`
	BackupFileName   string         `gorm:"column:backup_file_name" json:"backupFileName"`
	BackupFilePath   string         `gorm:"column:backup_file_path" json:"backupFilePath"`
	BackupFileSize   *int64         `gorm:"column:backup_file_size" json:"backupFileSize"`
	BackupTime       time.Time      `gorm:"column:backup_time" json:"backupTime"`
	BackupDuration   *int           `gorm:"column:backup_duration" json:"backupDuration"`
	BackupHandler    string         `gorm:"column:backup_handler" json:"backupHandler"`
	RestoreTime      *time.Time     `gorm:"column:restore_time" json:"restoreTime"`
	RestoreDuration  *int           `gorm:"column:restore_duration" json:"restoreDuration"`
	RestoreStatus    string         `gorm:"column:restore_status" json:"restoreStatus"`
	RestoreHandler   string         `gorm:"column:restore_handler" json:"restoreHandler"`
	ErrorMessage     string         `gorm:"column:error_message" json:"errorMessage"`
	Status           string         `gorm:"column:status" json:"status"`
	CreatedAt        *time.Time     `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt        *time.Time     `gorm:"column:updated_at" json:"updatedAt"`
	Remarks          string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt        gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (BackupRestore) TableName() string {
	return "sys_backup_restore"
}
