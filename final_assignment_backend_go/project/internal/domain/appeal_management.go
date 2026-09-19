package domain

import (
	"time"

	"gorm.io/gorm"
)

// AppealManagement maps traffic.appeal_record and emits camelCase JSON.
type AppealManagement struct {
	AppealID            int            `gorm:"column:appeal_id;primaryKey;autoIncrement" json:"appealId"`
	OffenseID           int            `gorm:"column:offense_id" json:"offenseId"`
	DriverID            *int           `gorm:"column:driver_id" json:"driverId"`
	AppealNumber        string         `gorm:"column:appeal_number" json:"appealNumber"`
	AppellantName       string         `gorm:"column:appellant_name" json:"appellantName"`
	AppellantIDCard     string         `gorm:"column:appellant_id_card" json:"appellantIdCard"`
	AppellantContact    string         `gorm:"column:appellant_contact" json:"appellantContact"`
	AppellantEmail      string         `gorm:"column:appellant_email" json:"appellantEmail"`
	AppellantAddress    string         `gorm:"column:appellant_address" json:"appellantAddress"`
	AppealType          string         `gorm:"column:appeal_type" json:"appealType"`
	AppealReason        string         `gorm:"column:appeal_reason" json:"appealReason"`
	AppealTime          time.Time      `gorm:"column:appeal_time" json:"appealTime"`
	EvidenceDescription string         `gorm:"column:evidence_description" json:"evidenceDescription"`
	EvidenceURLs        string         `gorm:"column:evidence_urls" json:"evidenceUrls"`
	AcceptanceStatus    string         `gorm:"column:acceptance_status" json:"acceptanceStatus"`
	AcceptanceTime      *time.Time     `gorm:"column:acceptance_time" json:"acceptanceTime"`
	AcceptanceHandler   string         `gorm:"column:acceptance_handler" json:"acceptanceHandler"`
	RejectionReason     string         `gorm:"column:rejection_reason" json:"rejectionReason"`
	ProcessStatus       string         `gorm:"column:process_status" json:"processStatus"`
	ProcessTime         *time.Time     `gorm:"column:process_time" json:"processTime"`
	ProcessResult       string         `gorm:"column:process_result" json:"processResult"`
	ProcessHandler      string         `gorm:"column:process_handler" json:"processHandler"`
	CreatedAt           *time.Time     `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt           *time.Time     `gorm:"column:updated_at" json:"updatedAt"`
	CreatedBy           string         `gorm:"column:created_by" json:"createdBy"`
	UpdatedBy           string         `gorm:"column:updated_by" json:"updatedBy"`
	Remarks             string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt           gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (AppealManagement) TableName() string {
	return "appeal_record"
}
