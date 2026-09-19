package domain

import "time"

// OffenseDetails maps the live view_offense_details read model.
type OffenseDetails struct {
	OffenseID           int        `gorm:"column:offense_id;primaryKey" json:"offenseId"`
	OffenseNumber       string     `gorm:"column:offense_number" json:"offenseNumber"`
	OffenseCode         string     `gorm:"column:offense_code" json:"offenseCode"`
	OffenseName         string     `gorm:"column:offense_name" json:"offenseName"`
	OffenseCategory     string     `gorm:"column:offense_category" json:"offenseCategory"`
	OffenseTime         time.Time  `gorm:"column:offense_time" json:"offenseTime"`
	OffenseLocation     string     `gorm:"column:offense_location" json:"offenseLocation"`
	OffenseProvince     string     `gorm:"column:offense_province" json:"offenseProvince"`
	OffenseCity         string     `gorm:"column:offense_city" json:"offenseCity"`
	DriverID            *int       `gorm:"column:driver_id" json:"driverId"`
	DriverName          string     `gorm:"column:driver_name" json:"driverName"`
	DriverIDCardNumber  string     `gorm:"column:driver_id_card" json:"driverIdCardNumber"`
	DriverLicenseNumber string     `gorm:"column:driver_license_number" json:"driverLicenseNumber"`
	DriverContact       string     `gorm:"column:driver_contact" json:"driverContact"`
	VehicleID           *int       `gorm:"column:vehicle_id" json:"vehicleId"`
	LicensePlate        string     `gorm:"column:license_plate" json:"licensePlate"`
	VehicleType         string     `gorm:"column:vehicle_type" json:"vehicleType"`
	OwnerName           string     `gorm:"column:vehicle_owner" json:"ownerName"`
	OwnerIDCard         string     `gorm:"column:owner_id_card" json:"ownerIdCard"`
	FineAmount          float64    `gorm:"column:fine_amount" json:"fineAmount"`
	DeductedPoints      int        `gorm:"column:deducted_points" json:"deductedPoints"`
	ProcessStatus       string     `gorm:"column:process_status" json:"processStatus"`
	ProcessTime         *time.Time `gorm:"column:process_time" json:"processTime"`
	ProcessHandler      string     `gorm:"column:process_handler" json:"processHandler"`
	EnforcementAgency   string     `gorm:"column:enforcement_agency" json:"enforcementAgency"`
	CreatedAt           *time.Time `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt           *time.Time `gorm:"column:updated_at" json:"updatedAt"`
}

func (OffenseDetails) TableName() string {
	return "view_offense_details"
}
