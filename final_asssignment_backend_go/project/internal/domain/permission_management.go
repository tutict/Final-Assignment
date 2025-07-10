package domain

import (
	"time"

	"gorm.io/gorm"
)

// PermissionManagement 表示 permission_management 表的实体
type PermissionManagement struct {
	PermissionID          int            `gorm:"column:permission_id;primaryKey;autoIncrement" json:"permission_id"`
	PermissionName        string         `gorm:"column:permission_name" json:"permission_name"`
	PermissionDescription string         `gorm:"column:permission_description" json:"permission_description"`
	CreatedTime           time.Time      `gorm:"column:created_time" json:"created_time"`
	ModifiedTime          time.Time      `gorm:"column:modified_time" json:"modified_time"`
	Remarks               string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt             gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (PermissionManagement) TableName() string {
	return "permission_management"
}
