package offense

import (
	"final_assignment_backend_go/project/internal/service/shared"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

type OffenseInformationService struct {
	repo *repo.OffenseInformationRepo
}

func NewOffenseInformationService(repo *repo.OffenseInformationRepo) *OffenseInformationService {
	return &OffenseInformationService{repo: repo}
}

func (s *OffenseInformationService) CreateOffense(offense *domain.OffenseInformation) error {
	return s.repo.Create(offense)
}

func (s *OffenseInformationService) DB() *gorm.DB { return s.repo.DB() }

func (s *OffenseInformationService) CheckAndInsertIdempotency(key string, offense *domain.OffenseInformation, operation string) error {
	if err := shared.CheckIdempotency(key, "offense:"+operation); err != nil {
		return err
	}
	if strings.EqualFold(operation, "create") {
		if offense.OffenseTime.IsZero() {
			offense.OffenseTime = time.Now()
		}
		return s.DB().Create(offense).Error
	}
	return s.DB().Save(offense).Error
}

func (s *OffenseInformationService) GetOffenseByID(id int) (*domain.OffenseInformation, error) {
	var offense domain.OffenseInformation
	err := s.DB().Where("offense_id = ?", id).First(&offense).Error
	if err != nil {
		return &offense, err
	}
	list := []domain.OffenseInformation{offense}
	s.enrichOffenses(list)
	return &list[0], nil
}

func (s *OffenseInformationService) GetAllOffenses() ([]domain.OffenseInformation, error) {
	offenses, err := s.repo.FindAll()
	if err != nil {
		return offenses, err
	}
	s.enrichOffenses(offenses)
	return offenses, nil
}

func (s *OffenseInformationService) DeleteOffense(id int) error {
	return s.DB().Where("offense_id = ?", id).Delete(&domain.OffenseInformation{}).Error
}

func (s *OffenseInformationService) GetOffensesByTimeRange(start time.Time, end time.Time) ([]domain.OffenseInformation, error) {
	var offenses []domain.OffenseInformation
	err := s.DB().Where("offense_time BETWEEN ? AND ?", start, end).Find(&offenses).Error
	s.enrichOffenses(offenses)
	return offenses, err
}

func (s *OffenseInformationService) SearchByOffenseType(query string, page int, size int) ([]domain.OffenseInformation, error) {
	return s.searchOffenses("offense_name", query, page, size)
}

func (s *OffenseInformationService) SearchByDriverName(query string, page int, size int) ([]domain.OffenseInformation, error) {
	return s.searchOffenses("driver_name", query, page, size)
}

func (s *OffenseInformationService) SearchByLicensePlate(query string, page int, size int) ([]domain.OffenseInformation, error) {
	return s.searchOffenses("license_plate", query, page, size)
}

func (s *OffenseInformationService) searchOffenses(column string, query string, page int, size int) ([]domain.OffenseInformation, error) {
	offset, limit := shared.PageBounds(page, size)
	var ids []int
	q := s.DB().Table("view_offense_details").Select("offense_id")
	switch column {
	case "offense_name":
		q = q.Where("offense_name LIKE ? OR offense_code LIKE ? OR offense_category LIKE ?", shared.Like(query), shared.Like(query), shared.Like(query))
	default:
		q = q.Where(column+" LIKE ?", shared.Like(query))
	}
	if err := q.Offset(offset).Limit(limit).Pluck("offense_id", &ids).Error; err != nil {
		return nil, err
	}
	if len(ids) == 0 {
		return []domain.OffenseInformation{}, nil
	}
	var offenses []domain.OffenseInformation
	err := s.DB().Where("offense_id IN ?", ids).Find(&offenses).Error
	s.enrichOffenses(offenses)
	return offenses, err
}

func (s *OffenseInformationService) FilterForRequester(username string, elevated bool, offenses []domain.OffenseInformation) []domain.OffenseInformation {
	if elevated {
		return offenses
	}
	driverID, ok := shared.RequesterDriverID(s.DB(), username)
	if !ok {
		return []domain.OffenseInformation{}
	}
	out := make([]domain.OffenseInformation, 0, len(offenses))
	for _, offense := range offenses {
		if offense.DriverID != nil && *offense.DriverID == driverID {
			out = append(out, offense)
		}
	}
	return out
}

func (s *OffenseInformationService) CanAccess(username string, elevated bool, offense *domain.OffenseInformation) bool {
	if offense == nil {
		return false
	}
	if elevated {
		return true
	}
	driverID, ok := shared.RequesterDriverID(s.DB(), username)
	return ok && offense.DriverID != nil && *offense.DriverID == driverID
}

func (s *OffenseInformationService) ListForRequester(username string, elevated bool) ([]domain.OffenseInformation, error) {
	if elevated {
		return s.GetAllOffenses()
	}
	driverID, ok := shared.RequesterDriverID(s.DB(), username)
	if !ok {
		return []domain.OffenseInformation{}, nil
	}
	var offenses []domain.OffenseInformation
	err := s.DB().Where("driver_id = ?", driverID).Find(&offenses).Error
	s.enrichOffenses(offenses)
	return offenses, err
}

func (s *OffenseInformationService) enrichOffenses(offenses []domain.OffenseInformation) {
	if len(offenses) == 0 {
		return
	}
	ids := make([]int, 0, len(offenses))
	index := map[int]int{}
	for i, item := range offenses {
		ids = append(ids, item.OffenseID)
		index[item.OffenseID] = i
	}
	var rows []domain.OffenseDetails
	if err := s.DB().Where("offense_id IN ?", ids).Find(&rows).Error; err != nil {
		return
	}
	for _, row := range rows {
		i, ok := index[row.OffenseID]
		if !ok {
			continue
		}
		offenses[i].DriverName = row.DriverName
		offenses[i].DriverLicenseNumber = row.DriverLicenseNumber
		offenses[i].LicensePlate = row.LicensePlate
		offenses[i].VehicleType = row.VehicleType
		if row.OffenseName != "" {
			offenses[i].OffenseType = row.OffenseName
		} else {
			offenses[i].OffenseType = row.OffenseCode
		}
	}
}
