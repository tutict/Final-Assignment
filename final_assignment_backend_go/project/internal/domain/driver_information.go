package domain

import (
	"time"

	"gorm.io/gorm"
)

// DriverInformation maps traffic.driver_information and emits camelCase JSON.
type DriverInformation struct {
	DriverID            int            `gorm:"column:driver_id;primaryKey;autoIncrement" json:"driverId"`
	AuthUserID          *int64         `gorm:"column:auth_user_id" json:"authUserId"`
	Name                string         `gorm:"column:name" json:"name"`
	IDCardNumber        string         `gorm:"column:id_card_number" json:"idCardNumber"`
	Gender              string         `gorm:"column:gender" json:"gender"`
	Birthdate           *time.Time     `gorm:"column:birthdate" json:"birthdate"`
	ContactNumber       string         `gorm:"column:contact_number" json:"contactNumber"`
	Email               string         `gorm:"column:email" json:"email"`
	Address             string         `gorm:"column:address" json:"address"`
	DriverLicenseNumber string         `gorm:"column:driver_license_number" json:"driverLicenseNumber"`
	LicenseType         string         `gorm:"column:license_type" json:"licenseType"`
	AllowedVehicleType  string         `gorm:"-" json:"allowedVehicleType"`
	FirstLicenseDate    *time.Time     `gorm:"column:first_license_date" json:"firstLicenseDate"`
	IssueDate           *time.Time     `gorm:"column:issue_date" json:"issueDate"`
	ExpiryDate          *time.Time     `gorm:"column:expiry_date" json:"expiryDate"`
	IssuingAuthority    string         `gorm:"column:issuing_authority" json:"issuingAuthority"`
	CurrentPoints       int            `gorm:"column:current_points" json:"currentPoints"`
	TotalDeductedPoints int            `gorm:"column:total_deducted_points" json:"totalDeductedPoints"`
	Status              string         `gorm:"column:status" json:"status"`
	CreatedAt           *time.Time     `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt           *time.Time     `gorm:"column:updated_at" json:"updatedAt"`
	CreatedBy           string         `gorm:"column:created_by" json:"createdBy"`
	UpdatedBy           string         `gorm:"column:updated_by" json:"updatedBy"`
	Remarks             string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt           gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
}

func (DriverInformation) TableName() string {
	return "driver_information"
}

func (d *DriverInformation) AfterFind(tx *gorm.DB) error {
	d.AllowedVehicleType = d.LicenseType
	return nil
}

func (d *DriverInformation) BeforeSave(tx *gorm.DB) error {
	if d.LicenseType == "" && d.AllowedVehicleType != "" {
		d.LicenseType = d.AllowedVehicleType
	}
	return nil
}
