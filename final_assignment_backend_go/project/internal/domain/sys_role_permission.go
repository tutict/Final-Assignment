package domain

import (
	"time"

	"gorm.io/gorm"
)

// SysRolePermission maps traffic.sys_role_permission.
type SysRolePermission struct {
	ID           int64          `gorm:"column:id;primaryKey" json:"id"`
	RoleID       int            `gorm:"column:role_id" json:"roleId"`
	PermissionID int            `gorm:"column:permission_id" json:"permissionId"`
	CreatedAt    *time.Time     `gorm:"column:created_at" json:"createdAt"`
	CreatedBy    string         `gorm:"column:created_by" json:"createdBy"`
	DeletedAt    gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (SysRolePermission) TableName() string { return "sys_role_permission" }
