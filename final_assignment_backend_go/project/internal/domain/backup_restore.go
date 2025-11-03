package domain

import (
	"time"

	"gorm.io/gorm"
)

// BackupRestore 表示 backup_restore 表的实体
type BackupRestore struct {
	BackupID       int            `gorm:"column:backup_id;primaryKey;autoIncrement" json:"backup_id"`
	BackupFileName string         `gorm:"column:backup_file_name" json:"backup_file_name"`
	BackupTime     time.Time      `gorm:"column:backup_time" json:"backup_time"`
	RestoreTime    time.Time      `gorm:"column:restore_time" json:"restore_time"`
	RestoreStatus  string         `gorm:"column:restore_status" json:"restore_status"`
	Remarks        string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt      gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (BackupRestore) TableName() string {
	return "backup_restore"
}
