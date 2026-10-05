package domain

import (
	"time"

	"gorm.io/gorm"
)

// SysUserRole maps traffic.sys_user_role, including the relation id the
// frontend uses for update and delete.
type SysUserRole struct {
	ID        int64          `gorm:"column:id;primaryKey" json:"id"`
	UserID    int            `gorm:"column:user_id" json:"userId"`
	RoleID    int            `gorm:"column:role_id" json:"roleId"`
	CreatedAt *time.Time     `gorm:"column:created_at" json:"createdAt"`
	CreatedBy string         `gorm:"column:created_by" json:"createdBy"`
	DeletedAt gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (SysUserRole) TableName() string { return "sys_user_role" }
