package domain

import (
	"time"

	"gorm.io/gorm"
)

// UserManagement 表示 user_management 表的实体
type UserManagement struct {
	UserID        int            `gorm:"column:user_id;primaryKey;autoIncrement" json:"user_id"`
	Username      string         `gorm:"column:username" json:"username"`
	Password      string         `gorm:"column:password" json:"password"`
	ContactNumber string         `gorm:"column:contact_number" json:"contact_number"`
	Email         string         `gorm:"column:email" json:"email"`
	Status        string         `gorm:"column:status" json:"status"`
	CreatedTime   time.Time      `gorm:"column:created_time" json:"created_time"`
	ModifiedTime  time.Time      `gorm:"column:modified_time" json:"modified_time"`
	Remarks       string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt     gorm.DeletedAt `gorm:"index"` // 软删除字段（可选，GORM 默认支持）
}

// TableName 指定数据库表名
func (UserManagement) TableName() string {
	return "user_management"
}
