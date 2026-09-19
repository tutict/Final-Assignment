package domain

import (
	"time"

	"gorm.io/gorm"
)

// RoleManagement maps traffic.sys_role and emits camelCase JSON.
type RoleManagement struct {
	RoleID          int            `gorm:"column:role_id;primaryKey;autoIncrement" json:"roleId"`
	RoleCode        string         `gorm:"column:role_code" json:"roleCode"`
	RoleName        string         `gorm:"column:role_name" json:"roleName"`
	RoleType        string         `gorm:"column:role_type" json:"roleType"`
	RoleDescription string         `gorm:"column:role_description" json:"roleDescription"`
	DataScope       string         `gorm:"column:data_scope" json:"dataScope"`
	Status          string         `gorm:"column:status" json:"status"`
	SortOrder       int            `gorm:"column:sort_order" json:"sortOrder"`
	CreatedTime     *time.Time     `gorm:"column:created_at" json:"createdTime"`
	ModifiedTime    *time.Time     `gorm:"column:updated_at" json:"modifiedTime"`
	CreatedBy       string         `gorm:"column:created_by" json:"createdBy"`
	UpdatedBy       string         `gorm:"column:updated_by" json:"updatedBy"`
	Remarks         string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt       gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (RoleManagement) TableName() string {
	return "sys_role"
}
