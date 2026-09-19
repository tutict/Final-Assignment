package domain

import (
	"time"

	"gorm.io/gorm"
)

// PermissionManagement maps traffic.sys_permission and emits camelCase JSON.
type PermissionManagement struct {
	PermissionID          int            `gorm:"column:permission_id;primaryKey;autoIncrement" json:"permissionId"`
	ParentID              *int           `gorm:"column:parent_id" json:"parentId"`
	PermissionCode        string         `gorm:"column:permission_code" json:"permissionCode"`
	PermissionName        string         `gorm:"column:permission_name" json:"permissionName"`
	PermissionType        string         `gorm:"column:permission_type" json:"permissionType"`
	PermissionDescription string         `gorm:"column:permission_description" json:"permissionDescription"`
	MenuPath              string         `gorm:"column:menu_path" json:"menuPath"`
	MenuIcon              string         `gorm:"column:menu_icon" json:"menuIcon"`
	Component             string         `gorm:"column:component" json:"component"`
	APIPath               string         `gorm:"column:api_path" json:"apiPath"`
	APIMethod             string         `gorm:"column:api_method" json:"apiMethod"`
	IsVisible             *bool          `gorm:"column:is_visible" json:"isVisible"`
	IsExternal            *bool          `gorm:"column:is_external" json:"isExternal"`
	SortOrder             int            `gorm:"column:sort_order" json:"sortOrder"`
	Status                string         `gorm:"column:status" json:"status"`
	CreatedTime           *time.Time     `gorm:"column:created_at" json:"createdTime"`
	ModifiedTime          *time.Time     `gorm:"column:updated_at" json:"modifiedTime"`
	CreatedBy             string         `gorm:"column:created_by" json:"createdBy"`
	UpdatedBy             string         `gorm:"column:updated_by" json:"updatedBy"`
	Remarks               string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt             gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (PermissionManagement) TableName() string {
	return "sys_permission"
}
