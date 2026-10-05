package domain

import (
	"time"

	"gorm.io/gorm"
)

// SysDict maps traffic.sys_dict and uses the camelCase names the settings page reads.
type SysDict struct {
	DictID          int            `gorm:"column:dict_id;primaryKey" json:"dictId"`
	ParentID        *int           `gorm:"column:parent_id" json:"parentId"`
	DictType        string         `gorm:"column:dict_type" json:"dictType"`
	DictCode        string         `gorm:"column:dict_code" json:"dictCode"`
	DictLabel       string         `gorm:"column:dict_label" json:"dictLabel"`
	DictValue       string         `gorm:"column:dict_value" json:"dictValue"`
	DictDescription string         `gorm:"column:dict_description" json:"dictDescription"`
	CssClass        string         `gorm:"column:css_class" json:"cssClass"`
	ListClass       string         `gorm:"column:list_class" json:"listClass"`
	IsDefault       bool           `gorm:"column:is_default" json:"isDefault"`
	IsFixed         bool           `gorm:"column:is_fixed" json:"isFixed"`
	Status          string         `gorm:"column:status" json:"status"`
	SortOrder       int            `gorm:"column:sort_order" json:"sortOrder"`
	CreatedAt       *time.Time     `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt       *time.Time     `gorm:"column:updated_at" json:"updatedAt"`
	CreatedBy       string         `gorm:"column:created_by" json:"createdBy"`
	UpdatedBy       string         `gorm:"column:updated_by" json:"updatedBy"`
	Remarks         string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt       gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (SysDict) TableName() string { return "sys_dict" }
