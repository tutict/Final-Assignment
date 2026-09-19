package domain

import (
	"time"

	"gorm.io/gorm"
)

// FineInformation maps traffic.fine_record and emits the camelCase JSON
// contract used by the React/Flutter clients.
type FineInformation struct {
	FineID           int            `gorm:"column:fine_id;primaryKey;autoIncrement" json:"fineId"`
	OffenseID        int            `gorm:"column:offense_id" json:"offenseId"`
	DriverID         *int           `gorm:"column:driver_id" json:"driverId"`
	FineNumber       string         `gorm:"column:fine_number" json:"fineNumber"`
	FineAmount       float64        `gorm:"column:fine_amount" json:"fineAmount"`
	LateFee          float64        `gorm:"column:late_fee" json:"lateFee"`
	TotalAmount      float64        `gorm:"column:total_amount" json:"totalAmount"`
	FineDate         *time.Time     `gorm:"column:fine_date" json:"fineDate"`
	PaymentDeadline  *time.Time     `gorm:"column:payment_deadline" json:"paymentDeadline"`
	IssuingAuthority string         `gorm:"column:issuing_authority" json:"issuingAuthority"`
	Handler          string         `gorm:"column:handler" json:"handler"`
	Approver         string         `gorm:"column:approver" json:"approver"`
	PaymentStatus    string         `gorm:"column:payment_status" json:"paymentStatus"`
	PaidAmount       float64        `gorm:"column:paid_amount" json:"paidAmount"`
	UnpaidAmount     float64        `gorm:"column:unpaid_amount" json:"unpaidAmount"`
	Status           string         `gorm:"-" json:"status"`
	CreatedAt        *time.Time     `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt        *time.Time     `gorm:"column:updated_at" json:"updatedAt"`
	CreatedBy        string         `gorm:"column:created_by" json:"createdBy"`
	UpdatedBy        string         `gorm:"column:updated_by" json:"updatedBy"`
	Remarks          string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt        gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (FineInformation) TableName() string {
	return "fine_record"
}

func (f *FineInformation) AfterFind(tx *gorm.DB) error {
	if f.Status == "" {
		f.Status = f.PaymentStatus
	}
	return nil
}

func (f *FineInformation) BeforeSave(tx *gorm.DB) error {
	if f.PaymentStatus == "" && f.Status != "" {
		f.PaymentStatus = f.Status
	}
	if f.TotalAmount == 0 {
		f.TotalAmount = f.FineAmount + f.LateFee
	}
	return nil
}
