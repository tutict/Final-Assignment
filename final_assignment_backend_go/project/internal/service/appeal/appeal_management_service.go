package appeal

import (
	"errors"
	"final_assignment_backend_go/project/internal/service/shared"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

type AppealManagementService struct {
	repo *repo.AppealManagementRepo
}

func NewAppealManagementService(repo *repo.AppealManagementRepo) *AppealManagementService {
	return &AppealManagementService{repo: repo}
}

func (s *AppealManagementService) CreateAppeal(appeal *domain.AppealManagement) error {
	return s.repo.Create(appeal)
}

func (s *AppealManagementService) DB() *gorm.DB {
	return s.repo.DB()
}

func (s *AppealManagementService) CheckAndInsertIdempotency(key string, appeal *domain.AppealManagement, operation string) (*domain.AppealManagement, error) {
	if err := shared.CheckIdempotency(key, "appeal:"+operation); err != nil {
		return nil, err
	}
	switch strings.ToLower(operation) {
	case "create":
		if appeal.AppealTime.IsZero() {
			appeal.AppealTime = time.Now()
		}
		if strings.TrimSpace(appeal.AppealNumber) == "" {
			appeal.AppealNumber = "AP" + time.Now().Format("20060102150405")
		}
		if strings.TrimSpace(appeal.AppealType) == "" {
			appeal.AppealType = "Other"
		}
		if strings.TrimSpace(appeal.ProcessStatus) == "" {
			appeal.ProcessStatus = "Unprocessed"
		}
		if strings.TrimSpace(appeal.AcceptanceStatus) == "" {
			appeal.AcceptanceStatus = "Pending"
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
	err := s.DB().Where("appellant_name LIKE ?", shared.Like(name)).Find(&appeals).Error
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
	err := s.DB().Where("appellant_id_card = ?", idCard).Find(&appeals).Error
	return appeals, err
}

func (s *AppealManagementService) GetAppealsByContactNumber(contact string) ([]domain.AppealManagement, error) {
	var appeals []domain.AppealManagement
	err := s.DB().Where("appellant_contact = ?", contact).Find(&appeals).Error
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

func (s *AppealManagementService) FilterForRequester(username string, elevated bool, appeals []domain.AppealManagement) []domain.AppealManagement {
	if elevated {
		return appeals
	}
	driverID, ok := shared.RequesterDriverID(s.DB(), username)
	if !ok {
		return []domain.AppealManagement{}
	}
	out := make([]domain.AppealManagement, 0, len(appeals))
	for _, appeal := range appeals {
		if appeal.DriverID != nil && *appeal.DriverID == driverID {
			out = append(out, appeal)
		}
	}
	return out
}

func (s *AppealManagementService) CanAccess(username string, elevated bool, appeal *domain.AppealManagement) bool {
	if appeal == nil {
		return false
	}
	if elevated {
		return true
	}
	driverID, ok := shared.RequesterDriverID(s.DB(), username)
	return ok && appeal.DriverID != nil && *appeal.DriverID == driverID
}

func (s *AppealManagementService) ListForRequester(username string, elevated bool) ([]domain.AppealManagement, error) {
	if elevated {
		return s.GetAllAppeals()
	}
	driverID, ok := shared.RequesterDriverID(s.DB(), username)
	if !ok {
		return []domain.AppealManagement{}, nil
	}
	var appeals []domain.AppealManagement
	err := s.DB().Where("driver_id = ?", driverID).Find(&appeals).Error
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
		"PENDING":      true,
		"PROCESSING":   true,
		"APPROVED":     true,
		"REJECTED":     true,
		"COMPLETED":    true,
		"UNPROCESSED":  true,
		"UNDER_REVIEW": true,
		"UNDER-REVIEW": true,
		"WITHDRAWN":    true,
		"ACCEPTED":     true,
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

type AppealService = AppealManagementService
