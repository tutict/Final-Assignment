package service

import (
	"errors"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

func (s *AppealManagementService) DB() *gorm.DB {
	return s.repo.DB()
}

func (s *AppealManagementService) CheckAndInsertIdempotency(key string, appeal *domain.AppealManagement, operation string) (*domain.AppealManagement, error) {
	if err := checkIdempotency(key, "appeal:"+operation); err != nil {
		return nil, err
	}
	switch strings.ToLower(operation) {
	case "create":
		if appeal.AppealTime.IsZero() {
			appeal.AppealTime = time.Now()
		}
		if strings.TrimSpace(appeal.ProcessStatus) == "" {
			appeal.ProcessStatus = "PENDING"
		}
		if err := validateAppealStatus("", appeal.ProcessStatus); err != nil {
			return nil, err
		}
		return appeal, s.DB().Create(appeal).Error
	case "update":
		var existing domain.AppealManagement
		if err := s.DB().Where("appeal_id = ?", appeal.AppealID).First(&existing).Error; err != nil {
			return nil, err
		}
		if strings.TrimSpace(appeal.ProcessStatus) == "" {
			appeal.ProcessStatus = existing.ProcessStatus
		}
		if err := validateAppealStatus(existing.ProcessStatus, appeal.ProcessStatus); err != nil {
			return nil, err
		}
		return appeal, s.DB().Save(appeal).Error
	default:
		return nil, errors.New("unsupported appeal operation")
	}
}

func (s *AppealManagementService) GetAppealByID(id uint) (*domain.AppealManagement, error) {
	var appeal domain.AppealManagement
	err := s.DB().Where("appeal_id = ?", id).First(&appeal).Error
	return &appeal, err
}

func (s *AppealManagementService) GetAllAppeals() ([]domain.AppealManagement, error) {
	return s.repo.FindAll()
}

func (s *AppealManagementService) DeleteAppeal(id uint) error {
	return s.DB().Where("appeal_id = ?", id).Delete(&domain.AppealManagement{}).Error
}

func (s *AppealManagementService) GetAppealsByProcessStatus(status string) ([]domain.AppealManagement, error) {
	var appeals []domain.AppealManagement
	err := s.DB().Where("process_status = ?", status).Find(&appeals).Error
	return appeals, err
}

func (s *AppealManagementService) GetAppealsByAppellantName(name string) ([]domain.AppealManagement, error) {
	var appeals []domain.AppealManagement
	err := s.DB().Where("appellant_name LIKE ?", like(name)).Find(&appeals).Error
	return appeals, err
}

func (s *AppealManagementService) GetOffenseByAppealID(id uint) (*domain.OffenseInformation, error) {
	appeal, err := s.GetAppealByID(id)
	if err != nil {
		return nil, err
	}
	var offense domain.OffenseInformation
	err = s.DB().Where("offense_id = ?", appeal.OffenseID).First(&offense).Error
	return &offense, err
}

func (s *AppealManagementService) GetAppealsByIdCardNumber(idCard string) ([]domain.AppealManagement, error) {
	var appeals []domain.AppealManagement
	err := s.DB().Where("id_card_number = ?", idCard).Find(&appeals).Error
	return appeals, err
}

func (s *AppealManagementService) GetAppealsByContactNumber(contact string) ([]domain.AppealManagement, error) {
	var appeals []domain.AppealManagement
	err := s.DB().Where("contact_number = ?", contact).Find(&appeals).Error
	return appeals, err
}

func (s *AppealManagementService) GetAppealsByOffenseID(offenseID uint) ([]domain.AppealManagement, error) {
	var appeals []domain.AppealManagement
	err := s.DB().Where("offense_id = ?", offenseID).Find(&appeals).Error
	return appeals, err
}

func (s *AppealManagementService) GetAppealsByTimeRange(start time.Time, end time.Time) ([]domain.AppealManagement, error) {
	var appeals []domain.AppealManagement
	err := s.DB().Where("appeal_time BETWEEN ? AND ?", start, end).Find(&appeals).Error
	return appeals, err
}

func (s *AppealManagementService) CountAppealsByStatus(status string) (int64, error) {
	var count int64
	err := s.DB().Model(&domain.AppealManagement{}).Where("process_status = ?", status).Count(&count).Error
	return count, err
}

func validateAppealStatus(from string, to string) error {
	next := strings.ToUpper(strings.TrimSpace(to))
	if next == "" {
		return errors.New("appeal status is required")
	}
	valid := map[string]bool{
		"PENDING":    true,
		"PROCESSING": true,
		"APPROVED":   true,
		"REJECTED":   true,
		"COMPLETED":  true,
	}
	if !valid[next] {
		return errors.New("invalid appeal status")
	}
	current := strings.ToUpper(strings.TrimSpace(from))
	if current == "" || current == next {
		return nil
	}
	if current == "APPROVED" || current == "REJECTED" || current == "COMPLETED" {
		return errors.New("terminal appeal status cannot be changed")
	}
	return nil
}

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
		q = q.Where("license_plate LIKE ? OR owner_name LIKE ? OR id_card_number LIKE ?", pattern, pattern, pattern)
	}
	err := q.Offset(offset).Limit(limit).Find(&vehicles).Error
	return vehicles, err
}

func (s *VehicleService) GetLicensePlateAutocomplete(idCard string, prefix string, max int) []string {
	query := s.DB().Table("vehicle_information").Select("DISTINCT license_plate").Where("license_plate LIKE ?", prefixLike(prefix))
	if idCard != "" {
		query = query.Where("id_card_number = ?", idCard)
	}
	var values []string
	_ = query.Order("license_plate").Limit(max).Pluck("license_plate", &values).Error
	return values
}

func (s *VehicleService) GetVehicleTypeAutocomplete(idCard string, prefix string, max int) []string {
	query := s.DB().Table("vehicle_information").Select("DISTINCT vehicle_type").Where("vehicle_type LIKE ?", prefixLike(prefix))
	if idCard != "" {
		query = query.Where("id_card_number = ?", idCard)
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

func (s *VehicleService) GetByIdCardNumber(idCard string) []domain.VehicleInformation {
	var vehicles []domain.VehicleInformation
	_ = s.DB().Where("id_card_number = ?", idCard).Find(&vehicles).Error
	return vehicles
}

func (s *VehicleService) GetByStatus(status string) []domain.VehicleInformation {
	var vehicles []domain.VehicleInformation
	_ = s.DB().Where("current_status = ?", status).Find(&vehicles).Error
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

type TrafficViolationService struct {
	db *gorm.DB
}

func NewTrafficViolationService(db *gorm.DB) *TrafficViolationService {
	return &TrafficViolationService{db: db}
}

func (s *TrafficViolationService) GetViolationTypeCounts(startTime string, driverName string, licensePlate string) (map[string]int64, error) {
	query := s.db.Model(&domain.OffenseInformation{})
	if startTime != "" {
		query = query.Where("offense_time >= ?", startTime)
	}
	if driverName != "" {
		query = query.Where("driver_name LIKE ?", like(driverName))
	}
	if licensePlate != "" {
		query = query.Where("license_plate = ?", licensePlate)
	}
	return groupedCount(query, "offense_type")
}

func (s *TrafficViolationService) GetTimeSeriesData(startTime string, driverName string) ([]map[string]interface{}, error) {
	type row struct {
		Day   string
		Count int64
	}
	query := s.db.Model(&domain.OffenseInformation{}).
		Select("DATE(offense_time) AS day, COUNT(*) AS count").
		Group("DATE(offense_time)").
		Order("day")
	if startTime != "" {
		query = query.Where("offense_time >= ?", startTime)
	}
	if driverName != "" {
		query = query.Where("driver_name LIKE ?", like(driverName))
	}
	var rows []row
	if err := query.Scan(&rows).Error; err != nil {
		return nil, err
	}
	result := make([]map[string]interface{}, 0, len(rows))
	for _, item := range rows {
		result = append(result, map[string]interface{}{"date": item.Day, "count": item.Count})
	}
	return result, nil
}

func (s *TrafficViolationService) GetAppealReasonCounts(startTime string, appealReason string) (map[string]int64, error) {
	query := s.db.Model(&domain.AppealManagement{})
	if startTime != "" {
		query = query.Where("appeal_time >= ?", startTime)
	}
	if appealReason != "" {
		query = query.Where("appeal_reason LIKE ?", like(appealReason))
	}
	return groupedCount(query, "appeal_reason")
}

func (s *TrafficViolationService) GetFinePaymentStatus(startTime string) (map[string]int64, error) {
	query := s.db.Model(&domain.FineInformation{})
	if startTime != "" {
		query = query.Where("fine_time >= ?", startTime)
	}
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	return map[string]int64{"recorded": total}, nil
}

func groupedCount(query *gorm.DB, column string) (map[string]int64, error) {
	type row struct {
		Key   string
		Count int64
	}
	var rows []row
	if err := query.Select(column + " AS `key`, COUNT(*) AS count").Group(column).Scan(&rows).Error; err != nil {
		return nil, err
	}
	result := map[string]int64{}
	for _, item := range rows {
		result[item.Key] = item.Count
	}
	return result, nil
}
