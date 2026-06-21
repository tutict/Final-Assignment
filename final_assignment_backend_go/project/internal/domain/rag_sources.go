package domain

import (
	"time"

	"gorm.io/gorm"
)

type OffenseTypeDict struct {
	TypeID                int            `gorm:"column:type_id;primaryKey;autoIncrement" json:"typeId"`
	OffenseCode           string         `gorm:"column:offense_code" json:"offenseCode"`
	OffenseName           string         `gorm:"column:offense_name" json:"offenseName"`
	Category              string         `gorm:"column:category" json:"category"`
	Description           string         `gorm:"column:description" json:"description"`
	StandardFineAmount    *float64       `gorm:"column:standard_fine_amount" json:"standardFineAmount,omitempty"`
	MinFineAmount         *float64       `gorm:"column:min_fine_amount" json:"minFineAmount,omitempty"`
	MaxFineAmount         *float64       `gorm:"column:max_fine_amount" json:"maxFineAmount,omitempty"`
	DeductedPoints        *int           `gorm:"column:deducted_points" json:"deductedPoints,omitempty"`
	DetentionDays         *int           `gorm:"column:detention_days" json:"detentionDays,omitempty"`
	LicenseSuspensionDays *int           `gorm:"column:license_suspension_days" json:"licenseSuspensionDays,omitempty"`
	SeverityLevel         string         `gorm:"column:severity_level" json:"severityLevel"`
	LegalBasis            string         `gorm:"column:legal_basis" json:"legalBasis"`
	Status                string         `gorm:"column:status" json:"status"`
	CreatedAt             *time.Time     `gorm:"column:created_at" json:"createdAt,omitempty"`
	UpdatedAt             *time.Time     `gorm:"column:updated_at" json:"updatedAt,omitempty"`
	DeletedAt             gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
	Remarks               string         `gorm:"column:remarks" json:"remarks"`
}

func (OffenseTypeDict) TableName() string {
	return "offense_type_dict"
}

type AppealRecord struct {
	AppealID                   int64          `gorm:"column:appeal_id;primaryKey;autoIncrement" json:"appealId"`
	OffenseID                  *int64         `gorm:"column:offense_id" json:"offenseId,omitempty"`
	DriverID                   *int64         `gorm:"column:driver_id" json:"driverId,omitempty"`
	AppealNumber               string         `gorm:"column:appeal_number" json:"appealNumber"`
	AppellantName              string         `gorm:"column:appellant_name" json:"appellantName"`
	AppellantIDCard            string         `gorm:"column:appellant_id_card" json:"appellantIdCard"`
	AppellantIDCardCiphertext  string         `gorm:"column:appellant_id_card_ciphertext" json:"-"`
	AppellantIDCardBlindIndex  string         `gorm:"column:appellant_id_card_blind_index" json:"-"`
	AppellantContact           string         `gorm:"column:appellant_contact" json:"appellantContact"`
	AppellantContactCiphertext string         `gorm:"column:appellant_contact_ciphertext" json:"-"`
	AppellantContactBlindIndex string         `gorm:"column:appellant_contact_blind_index" json:"-"`
	AppellantEmail             string         `gorm:"column:appellant_email" json:"appellantEmail"`
	AppellantAddress           string         `gorm:"column:appellant_address" json:"appellantAddress"`
	AppealType                 string         `gorm:"column:appeal_type" json:"appealType"`
	AppealReason               string         `gorm:"column:appeal_reason" json:"appealReason"`
	AppealTime                 *time.Time     `gorm:"column:appeal_time" json:"appealTime,omitempty"`
	EvidenceDescription        string         `gorm:"column:evidence_description" json:"evidenceDescription"`
	EvidenceURLs               string         `gorm:"column:evidence_urls" json:"evidenceUrls"`
	AcceptanceStatus           string         `gorm:"column:acceptance_status" json:"acceptanceStatus"`
	AcceptanceTime             *time.Time     `gorm:"column:acceptance_time" json:"acceptanceTime,omitempty"`
	AcceptanceHandler          string         `gorm:"column:acceptance_handler" json:"acceptanceHandler"`
	RejectionReason            string         `gorm:"column:rejection_reason" json:"rejectionReason"`
	ProcessStatus              string         `gorm:"column:process_status" json:"processStatus"`
	ProcessTime                *time.Time     `gorm:"column:process_time" json:"processTime,omitempty"`
	ProcessResult              string         `gorm:"column:process_result" json:"processResult"`
	ProcessHandler             string         `gorm:"column:process_handler" json:"processHandler"`
	CreatedAt                  *time.Time     `gorm:"column:created_at" json:"createdAt,omitempty"`
	UpdatedAt                  *time.Time     `gorm:"column:updated_at" json:"updatedAt,omitempty"`
	CreatedBy                  string         `gorm:"column:created_by" json:"createdBy"`
	UpdatedBy                  string         `gorm:"column:updated_by" json:"updatedBy"`
	DeletedAt                  gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
	Remarks                    string         `gorm:"column:remarks" json:"remarks"`
}

func (AppealRecord) TableName() string {
	return "appeal_record"
}
