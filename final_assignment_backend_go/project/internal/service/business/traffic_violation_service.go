package business

import (
	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service/shared"

	"gorm.io/gorm"
)

type TrafficViolationService struct {
	db *gorm.DB
}

func NewTrafficViolationService(db *gorm.DB) *TrafficViolationService {
	return &TrafficViolationService{db: db}
}

func (s *TrafficViolationService) GetViolationTypeCounts(startTime string, driverName string, licensePlate string) (map[string]int64, error) {
	query := s.db.Table("view_offense_details")
	if startTime != "" {
		query = query.Where("offense_time >= ?", startTime)
	}
	if driverName != "" {
		query = query.Where("driver_name LIKE ?", shared.Like(driverName))
	}
	if licensePlate != "" {
		query = query.Where("license_plate = ?", licensePlate)
	}
	return groupedCount(query, "COALESCE(NULLIF(offense_name, ''), offense_code)")
}

func (s *TrafficViolationService) GetTimeSeriesData(startTime string, driverName string) ([]map[string]interface{}, error) {
	type row struct {
		Day   string
		Count int64
	}
	query := s.db.Table("view_offense_details").
		Select("DATE(offense_time) AS day, COUNT(*) AS count").
		Group("DATE(offense_time)").
		Order("day")
	if startTime != "" {
		query = query.Where("offense_time >= ?", startTime)
	}
	if driverName != "" {
		query = query.Where("driver_name LIKE ?", shared.Like(driverName))
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
		query = query.Where("appeal_reason LIKE ?", shared.Like(appealReason))
	}
	return groupedCount(query, "appeal_reason")
}

func (s *TrafficViolationService) GetFinePaymentStatus(startTime string) (map[string]int64, error) {
	query := s.db.Model(&domain.FineInformation{})
	if startTime != "" {
		query = query.Where("fine_date >= ?", startTime)
	}
	return groupedCount(query, "payment_status")
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
