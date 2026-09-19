package domain

import (
	"time"

	"gorm.io/gorm"
)

// VehicleInformation maps traffic.vehicle_information and emits the camelCase JSON
// contract used by the React/Flutter clients.
type VehicleInformation struct {
	VehicleID             int            `gorm:"column:vehicle_id;primaryKey;autoIncrement" json:"vehicleId"`
	LicensePlate          string         `gorm:"column:license_plate" json:"licensePlate"`
	PlateColor            string         `gorm:"column:plate_color" json:"plateColor"`
	VehicleType           string         `gorm:"column:vehicle_type" json:"vehicleType"`
	Brand                 string         `gorm:"column:brand" json:"brand"`
	Model                 string         `gorm:"column:model" json:"model"`
	VehicleColor          string         `gorm:"column:vehicle_color" json:"vehicleColor"`
	EngineNumber          string         `gorm:"column:engine_number" json:"engineNumber"`
	FrameNumber           string         `gorm:"column:frame_number" json:"frameNumber"`
	OwnerName             string         `gorm:"column:owner_name" json:"ownerName"`
	OwnerIDCard           string         `gorm:"column:owner_id_card" json:"ownerIdCard"`
	OwnerContact          string         `gorm:"column:owner_contact" json:"ownerContact"`
	OwnerAddress          string         `gorm:"column:owner_address" json:"ownerAddress"`
	FirstRegistrationDate *time.Time     `gorm:"column:first_registration_date" json:"firstRegistrationDate"`
	RegistrationDate      *time.Time     `gorm:"column:registration_date" json:"registrationDate"`
	IssuingAuthority      string         `gorm:"column:issuing_authority" json:"issuingAuthority"`
	Status                string         `gorm:"column:status" json:"status"`
	InspectionExpiryDate  *time.Time     `gorm:"column:inspection_expiry_date" json:"inspectionExpiryDate"`
	InsuranceExpiryDate   *time.Time     `gorm:"column:insurance_expiry_date" json:"insuranceExpiryDate"`
	DriverID              *int64         `gorm:"column:driver_id" json:"driverId"`
	Remarks               string         `gorm:"column:remarks" json:"remarks"`
	DeletedAt             gorm.DeletedAt `gorm:"index" json:"-"`
}

func (VehicleInformation) TableName() string {
	return "vehicle_information"
}
