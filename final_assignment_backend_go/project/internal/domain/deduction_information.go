package domain

import (
	"time"

	"gorm.io/gorm"
)

// DeductionInformation maps traffic.deduction_record and emits camelCase JSON.
type DeductionInformation struct {
	DeductionID    int            `gorm:"column:deduction_id;primaryKey;autoIncrement" json:"deductionId"`
	OffenseID      int            `gorm:"column:offense_id" json:"offenseId"`
	DriverID       int            `gorm:"column:driver_id" json:"driverId"`
	DeductedPoints int            `gorm:"column:deducted_points" json:"deductedPoints"`
	DeductionTime  time.Time      `gorm:"column:deduction_time" json:"deductionTime"`
	ScoringCycle   string         `gorm:"column:scoring_cycle" json:"scoringCycle"`
	Handler        string         `gorm:"column:handler" json:"handler"`
	HandlerDept    string         `gorm:"column:handler_dept" json:"handlerDept"`
	Approver       string         `gorm:"column:approver" json:"approver"`
	ApprovalTime   *time.Time     `gorm:"column:approval_time" json:"approvalTime"`
	Status         string         `gorm:"column:status" json:"status"`
	RestoreTime    *time.Time     `gorm:"column:restore_time" json:"restoreTime"`
	RestoreReason  string         `gorm:"column:restore_reason" json:"restoreReason"`
	CreatedAt      *time.Time     `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt      *time.Time     `gorm:"column:updated_at" json:"updatedAt"`
	CreatedBy      string         `gorm:"column:created_by" json:"createdBy"`
	UpdatedBy      string         `gorm:"column:updated_by" json:"updatedBy"`
	Remarks        string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt      gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (DeductionInformation) TableName() string {
	return "deduction_record"
}
