package domain

import (
	"time"

	"gorm.io/gorm"
)

// UserManagement maps traffic.sys_user and emits camelCase JSON.
type UserManagement struct {
	UserID          int            `gorm:"column:user_id;primaryKey;autoIncrement" json:"userId"`
	Username        string         `gorm:"column:username" json:"username"`
	Password        string         `gorm:"column:password" json:"-"`
	RealName        string         `gorm:"column:real_name" json:"realName"`
	ContactNumber   string         `gorm:"column:contact_number" json:"contactNumber"`
	Email           string         `gorm:"column:email" json:"email"`
	Department      string         `gorm:"column:department" json:"department"`
	Position        string         `gorm:"column:position" json:"position"`
	Status          string         `gorm:"column:status" json:"status"`
	LastLoginTime   *time.Time     `gorm:"column:last_login_time" json:"lastLoginTime"`
	CreatedTime     *time.Time     `gorm:"column:created_at" json:"createdTime"`
	ModifiedTime    *time.Time     `gorm:"column:updated_at" json:"modifiedTime"`
	Remarks         string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt       gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (UserManagement) TableName() string {
	return "sys_user"
}
