package domain

import (
	"time"

	"gorm.io/gorm"
)

// RoleManagement 表示 role_management 表的实体
type RoleManagement struct {
	RoleID          int            `gorm:"column:role_id;primaryKey;autoIncrement" json:"role_id"`
	RoleName        string         `gorm:"column:role_name" json:"role_name"`
	RoleDescription string         `gorm:"column:role_description" json:"role_description"`
	CreatedTime     time.Time      `gorm:"column:created_time" json:"created_time"`
	ModifiedTime    time.Time      `gorm:"column:modified_time" json:"modified_time"`
	Remarks         string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt       gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (RoleManagement) TableName() string {
	return "role_management"
}
