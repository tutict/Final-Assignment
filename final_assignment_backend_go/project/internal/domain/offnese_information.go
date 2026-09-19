package domain

import (
	"time"

	"gorm.io/gorm"
)

// OffenseInformation maps traffic.offense_record and emits camelCase JSON.
// DriverName/LicensePlate/OffenseType are filled from view_offense_details.
type OffenseInformation struct {
	OffenseID          int            `gorm:"column:offense_id;primaryKey;autoIncrement" json:"offenseId"`
	OffenseCode        string         `gorm:"column:offense_code" json:"offenseCode"`
	OffenseNumber      string         `gorm:"column:offense_number" json:"offenseNumber"`
	OffenseTime        time.Time      `gorm:"column:offense_time" json:"offenseTime"`
	OffenseLocation    string         `gorm:"column:offense_location" json:"offenseLocation"`
	OffenseProvince    string         `gorm:"column:offense_province" json:"offenseProvince"`
	OffenseCity        string         `gorm:"column:offense_city" json:"offenseCity"`
	DriverID           *int           `gorm:"column:driver_id" json:"driverId"`
	VehicleID          int            `gorm:"column:vehicle_id" json:"vehicleId"`
	OffenseDescription string         `gorm:"column:offense_description" json:"offenseDescription"`
	EvidenceType       string         `gorm:"column:evidence_type" json:"evidenceType"`
	EvidenceURLs       string         `gorm:"column:evidence_urls" json:"evidenceUrls"`
	EnforcementAgency  string         `gorm:"column:enforcement_agency" json:"enforcementAgency"`
	EnforcementOfficer string         `gorm:"column:enforcement_officer" json:"enforcementOfficer"`
	EnforcementDevice  string         `gorm:"column:enforcement_device" json:"enforcementDevice"`
	ProcessStatus      string         `gorm:"column:process_status" json:"processStatus"`
	NotificationStatus string         `gorm:"column:notification_status" json:"notificationStatus"`
	NotificationTime   *time.Time     `gorm:"column:notification_time" json:"notificationTime"`
	FineAmount         float64        `gorm:"column:fine_amount" json:"fineAmount"`
	DeductedPoints     int            `gorm:"column:deducted_points" json:"deductedPoints"`
	DetentionDays      int            `gorm:"column:detention_days" json:"detentionDays"`
	ProcessTime        *time.Time     `gorm:"column:process_time" json:"processTime"`
	ProcessHandler     string         `gorm:"column:process_handler" json:"processHandler"`
	ProcessResult      string         `gorm:"column:process_result" json:"processResult"`
	CreatedAt          *time.Time     `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt          *time.Time     `gorm:"column:updated_at" json:"updatedAt"`
	CreatedBy          string         `gorm:"column:created_by" json:"createdBy"`
	UpdatedBy          string         `gorm:"column:updated_by" json:"updatedBy"`
	Remarks            string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt          gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`

	DriverName          string `gorm:"-" json:"driverName"`
	DriverLicenseNumber string `gorm:"-" json:"driverLicenseNumber"`
	LicensePlate        string `gorm:"-" json:"licensePlate"`
	VehicleType         string `gorm:"-" json:"vehicleType"`
	OffenseType         string `gorm:"-" json:"offenseType"`
}

func (OffenseInformation) TableName() string {
	return "offense_record"
}
