package domain

import (
	"gorm.io/gorm"
)

// UserRole 表示 user_role 表的实体
type UserRole struct {
	UserID    int            `gorm:"column:user_id;primaryKey" json:"user_id"`
	RoleID    int            `gorm:"column:role_id;primaryKey" json:"role_id"`
	DeletedAt gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (UserRole) TableName() string {
	return "user_role"
}
