package service

import (
	"strings"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

type VehicleService struct {
	repo *repo.VehicleInformationRepo
}

func NewVehicleService(repo *repo.VehicleInformationRepo) *VehicleService {
	return &VehicleService{repo: repo}
}

func (s *VehicleService) DB() *gorm.DB {
	return s.repo.DB()
}

func (s *VehicleService) SearchVehicles(query string, page int, size int) ([]domain.VehicleInformation, error) {
	offset, limit := pageBounds(page, size)
	var vehicles []domain.VehicleInformation
	q := s.DB().Model(&domain.VehicleInformation{})
	if strings.TrimSpace(query) != "" {
		pattern := like(query)
		q = q.Where("license_plate LIKE ? OR owner_name LIKE ? OR owner_id_card LIKE ?", pattern, pattern, pattern)
	}
	err := q.Offset(offset).Limit(limit).Find(&vehicles).Error
	return vehicles, err
}

func (s *VehicleService) GetLicensePlateAutocomplete(idCard string, prefix string, max int) []string {
	query := s.DB().Table("vehicle_information").Select("DISTINCT license_plate").Where("license_plate LIKE ?", prefixLike(prefix))
	if idCard != "" {
		query = query.Where("owner_id_card = ?", idCard)
	}
	var values []string
	_ = query.Order("license_plate").Limit(max).Pluck("license_plate", &values).Error
	return values
}

func (s *VehicleService) GetVehicleTypeAutocomplete(idCard string, prefix string, max int) []string {
	query := s.DB().Table("vehicle_information").Select("DISTINCT vehicle_type").Where("vehicle_type LIKE ?", prefixLike(prefix))
	if idCard != "" {
		query = query.Where("owner_id_card = ?", idCard)
	}
	var values []string
	_ = query.Order("vehicle_type").Limit(max).Pluck("vehicle_type", &values).Error
	return values
}

func (s *VehicleService) GetLicensePlateGlobally(prefix string) []string {
	return distinctStrings(s.DB(), "vehicle_information", "license_plate", prefix, 10)
}

func (s *VehicleService) GetVehicleTypeGlobally(prefix string) []string {
	return distinctStrings(s.DB(), "vehicle_information", "vehicle_type", prefix, 10)
}

func (s *VehicleService) CreateVehicle(key string, vehicle *domain.VehicleInformation) error {
	if err := checkIdempotency(key, "vehicle:create"); err != nil {
		return err
	}
	return s.DB().Create(vehicle).Error
}

func (s *VehicleService) GetById(id int) (*domain.VehicleInformation, error) {
	var vehicle domain.VehicleInformation
	err := s.DB().Where("vehicle_id = ?", id).First(&vehicle).Error
	return &vehicle, err
}

func (s *VehicleService) GetByLicensePlate(plate string) (*domain.VehicleInformation, error) {
	var vehicle domain.VehicleInformation
	err := s.DB().Where("license_plate = ?", plate).First(&vehicle).Error
	return &vehicle, err
}

func (s *VehicleService) GetAll() []domain.VehicleInformation {
	vehicles, _ := s.repo.FindAll()
	return vehicles
}

func (s *VehicleService) GetByType(vehicleType string) []domain.VehicleInformation {
	var vehicles []domain.VehicleInformation
	_ = s.DB().Where("vehicle_type = ?", vehicleType).Find(&vehicles).Error
	return vehicles
}

func (s *VehicleService) GetByOwnerName(ownerName string) []domain.VehicleInformation {
	var vehicles []domain.VehicleInformation
	_ = s.DB().Where("owner_name LIKE ?", like(ownerName)).Find(&vehicles).Error
	return vehicles
}

func (s *VehicleService) GetByDriverId(driverID int) []domain.VehicleInformation {
	var vehicles []domain.VehicleInformation
	_ = s.DB().Where("driver_id = ?", driverID).Find(&vehicles).Error
	return vehicles
}

func (s *VehicleService) GetByIdCardNumber(idCard string) []domain.VehicleInformation {
	var vehicles []domain.VehicleInformation
	_ = s.DB().Where("owner_id_card = ?", idCard).Find(&vehicles).Error
	return vehicles
}

func (s *VehicleService) GetByStatus(status string) []domain.VehicleInformation {
	var vehicles []domain.VehicleInformation
	_ = s.DB().Where("status = ?", status).Find(&vehicles).Error
	return vehicles
}

func (s *VehicleService) UpdateVehicle(key string, vehicle *domain.VehicleInformation) error {
	if err := checkIdempotency(key, "vehicle:update"); err != nil {
		return err
	}
	return s.DB().Save(vehicle).Error
}

func (s *VehicleService) DeleteById(id int) error {
	return s.DB().Where("vehicle_id = ?", id).Delete(&domain.VehicleInformation{}).Error
}

func (s *VehicleService) DeleteByLicensePlate(plate string) error {
	return s.DB().Where("license_plate = ?", plate).Delete(&domain.VehicleInformation{}).Error
}

func (s *VehicleService) IsLicensePlateExists(plate string) bool {
	var count int64
	s.DB().Model(&domain.VehicleInformation{}).Where("license_plate = ?", plate).Count(&count)
	return count > 0
}

func (s *VehicleService) ListForRequester(username string, elevated bool) []domain.VehicleInformation {
	if elevated {
		return s.GetAll()
	}
	driverID, ok := requesterDriverID(s.DB(), username)
	if !ok {
		return []domain.VehicleInformation{}
	}
	return s.ownedVehicles(driverID)
}

func (s *VehicleService) FilterForRequester(username string, elevated bool, vehicles []domain.VehicleInformation) []domain.VehicleInformation {
	if elevated {
		return vehicles
	}
	driverID, ok := requesterDriverID(s.DB(), username)
	if !ok {
		return []domain.VehicleInformation{}
	}
	owned := map[int]bool{}
	for _, item := range s.ownedVehicles(driverID) {
		owned[item.VehicleID] = true
	}
	out := make([]domain.VehicleInformation, 0, len(vehicles))
	for _, item := range vehicles {
		if owned[item.VehicleID] {
			out = append(out, item)
		}
	}
	return out
}

func (s *VehicleService) CanAccess(username string, elevated bool, vehicle *domain.VehicleInformation) bool {
	if vehicle == nil {
		return false
	}
	if elevated {
		return true
	}
	driverID, ok := requesterDriverID(s.DB(), username)
	if !ok {
		return false
	}
	if vehicle.DriverID != nil && *vehicle.DriverID == int64(driverID) {
		return true
	}
	for _, item := range s.ownedVehicles(driverID) {
		if item.VehicleID == vehicle.VehicleID {
			return true
		}
	}
	return false
}

func (s *VehicleService) ownedVehicles(driverID int) []domain.VehicleInformation {
	byColumn := s.GetByDriverId(driverID)
	var bound []domain.VehicleInformation
	_ = s.DB().Joins("JOIN driver_vehicle ON driver_vehicle.vehicle_id = vehicle_information.vehicle_id AND driver_vehicle.deleted_at IS NULL").
		Where("driver_vehicle.driver_id = ?", driverID).
		Find(&bound).Error
	seen := map[int]bool{}
	out := make([]domain.VehicleInformation, 0, len(byColumn)+len(bound))
	for _, item := range append(byColumn, bound...) {
		if seen[item.VehicleID] {
			continue
		}
		seen[item.VehicleID] = true
		out = append(out, item)
	}
	return out
}
