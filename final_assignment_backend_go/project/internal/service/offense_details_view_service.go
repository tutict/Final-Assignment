package service

import (
	"errors"

	"final_assignment_backend_go/project/internal/domain"

	"gorm.io/gorm"
)

// OffenseDetailsViewService 组装违法记录详情视图，对齐 Spring 的
// com.tutict.finalassignmentbackend.service.offense.OffenseDetailService
// 与 dto.response.OffenseDetailResponse。
type OffenseDetailsViewService struct {
	db *gorm.DB
}

func NewOffenseDetailsViewService(db *gorm.DB) *OffenseDetailsViewService {
	return &OffenseDetailsViewService{db: db}
}

// OffenseDetailResponse 对齐 Spring 的 OffenseDetailResponse（camelCase 序列化）。
type OffenseDetailResponse struct {
	OffenseID       int                   `json:"offenseId"`
	OffenseType     string                `json:"offenseType"`
	OffenseLocation string                `json:"offenseLocation"`
	OffenseTime     string                `json:"offenseTime"`
	ProcessStatus   string                `json:"processStatus"`
	Driver          *OffenseDetailDriver  `json:"driver"`
	Vehicle         *OffenseDetailVehicle `json:"vehicle"`
	Fines           []OffenseDetailFine   `json:"fines"`
	Appeals         []OffenseDetailAppeal `json:"appeals"`
}

// OffenseDetailDriver 对齐 Spring 的 OffenseDetailResponse.DriverInfo。
type OffenseDetailDriver struct {
	DriverID            int    `json:"driverId"`
	Name                string `json:"name"`
	IDCardNumber        string `json:"idCardNumber"`
	DriverLicenseNumber string `json:"driverLicenseNumber"`
	ContactNumber       string `json:"contactNumber"`
}

// OffenseDetailVehicle 对齐 Spring 的 OffenseDetailResponse.VehicleInfo。
type OffenseDetailVehicle struct {
	VehicleID    int    `json:"vehicleId"`
	LicensePlate string `json:"licensePlate"`
	VehicleType  string `json:"vehicleType"`
	Brand        string `json:"brand"`
	Model        string `json:"model"`
}

// OffenseDetailFine 对齐 Spring 的 OffenseDetailResponse.FineInfo。
type OffenseDetailFine struct {
	FineID          int     `json:"fineId"`
	FineAmount      float64 `json:"fineAmount"`
	Status          string  `json:"status"`
	PaymentDeadline string  `json:"paymentDeadline"`
}

// OffenseDetailAppeal 对齐 Spring 的 OffenseDetailResponse.AppealInfo。
type OffenseDetailAppeal struct {
	AppealID      int    `json:"appealId"`
	AppealType    string `json:"appealType"`
	AppealReason  string `json:"appealReason"`
	ProcessStatus string `json:"processStatus"`
}

// GetOffenseDetail 组装单条违法记录的详情视图。
func (s *OffenseDetailsViewService) GetOffenseDetail(offenseID int) (*OffenseDetailResponse, error) {
	var offense domain.OffenseInformation
	if err := s.db.Where("offense_id = ?", offenseID).First(&offense).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	detail := &OffenseDetailResponse{
		OffenseID:       offense.OffenseID,
		OffenseType:     offense.OffenseCode,
		OffenseLocation: offense.OffenseLocation,
		OffenseTime:     offense.OffenseTime.Format("2006-01-02T15:04:05"),
		ProcessStatus:   offense.ProcessStatus,
		Fines:           []OffenseDetailFine{},
		Appeals:         []OffenseDetailAppeal{},
	}

	if offense.DriverID > 0 {
		var driver domain.DriverInformation
		if err := s.db.Where("driver_id = ?", offense.DriverID).First(&driver).Error; err == nil {
			detail.Driver = &OffenseDetailDriver{
				DriverID:            driver.DriverID,
				Name:                driver.Name,
				IDCardNumber:        driver.IDCardNumber,
				DriverLicenseNumber: driver.DriverLicenseNumber,
				ContactNumber:       driver.ContactNumber,
			}
		}
	}

	if offense.VehicleID > 0 {
		var vehicle domain.VehicleInformation
		if err := s.db.Where("vehicle_id = ?", offense.VehicleID).First(&vehicle).Error; err == nil {
			detail.Vehicle = &OffenseDetailVehicle{
				VehicleID:    vehicle.VehicleID,
				LicensePlate: vehicle.LicensePlate,
				VehicleType:  vehicle.VehicleType,
			}
		}
	}

	var fines []domain.FineInformation
	if err := s.db.Where("offense_id = ?", offenseID).Limit(100).Find(&fines).Error; err == nil {
		for _, fine := range fines {
			detail.Fines = append(detail.Fines, OffenseDetailFine{
				FineID:     fine.FineID,
				FineAmount: fine.FineAmount,
			})
		}
	}

	var appeals []domain.AppealManagement
	if err := s.db.Where("offense_id = ?", offenseID).Limit(100).Find(&appeals).Error; err == nil {
		for _, appeal := range appeals {
			detail.Appeals = append(detail.Appeals, OffenseDetailAppeal{
				AppealID:      appeal.AppealID,
				AppealReason:  appeal.AppealReason,
				ProcessStatus: appeal.ProcessStatus,
			})
		}
	}

	return detail, nil
}
