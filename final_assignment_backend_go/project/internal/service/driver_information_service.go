package service

import (
	"strings"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

type DriverInformationService struct {
	repo *repo.DriverInformationRepo
}

func NewDriverInformationService(repo *repo.DriverInformationRepo) *DriverInformationService {
	return &DriverInformationService{repo: repo}
}

func (s *DriverInformationService) CreateDriver(driver *domain.DriverInformation) error {
	return s.repo.Create(driver)
}

func (s *DriverInformationService) DB() *gorm.DB { return s.repo.DB() }

func (s *DriverInformationService) CheckAndInsertIdempotency(key string, driver *domain.DriverInformation, operation string) error {
	if err := checkIdempotency(key, "driver:"+operation); err != nil {
		return err
	}
	if strings.EqualFold(operation, "create") {
		return s.DB().Create(driver).Error
	}
	return s.DB().Save(driver).Error
}

func (s *DriverInformationService) GetDriverById(id int) (*domain.DriverInformation, error) {
	var driver domain.DriverInformation
	err := s.DB().Where("driver_id = ?", id).First(&driver).Error
	return &driver, err
}

func (s *DriverInformationService) GetAllDrivers() ([]domain.DriverInformation, error) {
	return s.repo.FindAll()
}

func (s *DriverInformationService) DeleteDriver(id int) error {
	return s.DB().Where("driver_id = ?", id).Delete(&domain.DriverInformation{}).Error
}

func (s *DriverInformationService) SearchByIdCardNumber(query string, page int, size int) ([]domain.DriverInformation, error) {
	return s.searchDrivers("id_card_number", query, page, size)
}

func (s *DriverInformationService) SearchByLicenseNumber(query string, page int, size int) ([]domain.DriverInformation, error) {
	return s.searchDrivers("driver_license_number", query, page, size)
}

func (s *DriverInformationService) SearchByName(query string, page int, size int) ([]domain.DriverInformation, error) {
	return s.searchDrivers("name", query, page, size)
}

func (s *DriverInformationService) searchDrivers(column string, query string, page int, size int) ([]domain.DriverInformation, error) {
	offset, limit := pageBounds(page, size)
	var drivers []domain.DriverInformation
	err := s.DB().Where(column+" LIKE ?", like(query)).Offset(offset).Limit(limit).Find(&drivers).Error
	return drivers, err
}

func (s *DriverInformationService) ListForRequester(username string, elevated bool) ([]domain.DriverInformation, error) {
	if elevated {
		return s.GetAllDrivers()
	}
	authID, ok := requesterAuthUserID(s.DB(), username)
	if !ok {
		return []domain.DriverInformation{}, nil
	}
	var drivers []domain.DriverInformation
	err := s.DB().Where("auth_user_id = ?", authID).Find(&drivers).Error
	return drivers, err
}

func (s *DriverInformationService) FilterForRequester(username string, elevated bool, drivers []domain.DriverInformation) []domain.DriverInformation {
	if elevated {
		return drivers
	}
	authID, ok := requesterAuthUserID(s.DB(), username)
	if !ok {
		return []domain.DriverInformation{}
	}
	out := make([]domain.DriverInformation, 0, len(drivers))
	for _, driver := range drivers {
		if driver.AuthUserID != nil && *driver.AuthUserID == authID {
			out = append(out, driver)
		}
	}
	return out
}

func (s *DriverInformationService) CanAccess(username string, elevated bool, driver *domain.DriverInformation) bool {
	if driver == nil {
		return false
	}
	if elevated {
		return true
	}
	authID, ok := requesterAuthUserID(s.DB(), username)
	return ok && driver.AuthUserID != nil && *driver.AuthUserID == authID
}
