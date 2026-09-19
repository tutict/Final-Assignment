package offense

import (
	"final_assignment_backend_go/project/internal/service/shared"
	"strconv"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

type DeductionInformationService struct {
	repo *repo.DeductionInformationRepo
}

func NewDeductionInformationService(repo *repo.DeductionInformationRepo) *DeductionInformationService {
	return &DeductionInformationService{repo: repo}
}

func (s *DeductionInformationService) CreateDeduction(deduction *domain.DeductionInformation) error {
	return s.repo.Create(deduction)
}

func (s *DeductionInformationService) DB() *gorm.DB { return s.repo.DB() }

func (s *DeductionInformationService) CheckAndInsertIdempotency(key string, deduction *domain.DeductionInformation, operation string) error {
	if err := shared.CheckIdempotency(key, "deduction:"+operation); err != nil {
		return err
	}
	if strings.EqualFold(operation, "create") {
		if deduction.DeductionTime.IsZero() {
			deduction.DeductionTime = time.Now()
		}
		if strings.TrimSpace(deduction.ScoringCycle) == "" {
			year := deduction.DeductionTime.Format("2006")
			nextYear, _ := strconv.Atoi(year)
			deduction.ScoringCycle = year + "-01-01至" + strconv.Itoa(nextYear+1) + "-01-01"
		}
		if strings.TrimSpace(deduction.Status) == "" {
			deduction.Status = "Effective"
		}
		if strings.TrimSpace(deduction.Handler) == "" {
			deduction.Handler = "system"
		}
		return s.DB().Create(deduction).Error
	}
	return s.DB().Save(deduction).Error
}

func (s *DeductionInformationService) GetDeductionById(id string) (*domain.DeductionInformation, error) {
	parsed, err := shared.ParseID(id)
	if err != nil {
		return nil, err
	}
	var deduction domain.DeductionInformation
	err = s.DB().Where("deduction_id = ?", parsed).First(&deduction).Error
	return &deduction, err
}

func (s *DeductionInformationService) GetAllDeductions() ([]domain.DeductionInformation, error) {
	return s.repo.FindAll()
}

func (s *DeductionInformationService) DeleteDeduction(id string) error {
	parsed, err := shared.ParseID(id)
	if err != nil {
		return err
	}
	return s.DB().Where("deduction_id = ?", parsed).Delete(&domain.DeductionInformation{}).Error
}

func (s *DeductionInformationService) GetDeductionsByHandler(handler string) ([]domain.DeductionInformation, error) {
	var deductions []domain.DeductionInformation
	err := s.DB().Where("handler = ?", handler).Find(&deductions).Error
	return deductions, err
}

func (s *DeductionInformationService) GetDeductionsByTimeRange(start time.Time, end time.Time) ([]domain.DeductionInformation, error) {
	var deductions []domain.DeductionInformation
	err := s.DB().Where("deduction_time BETWEEN ? AND ?", start, end).Find(&deductions).Error
	return deductions, err
}

func (s *DeductionInformationService) SearchByHandler(handler string, max int) ([]domain.DeductionInformation, error) {
	var deductions []domain.DeductionInformation
	err := s.DB().Where("handler LIKE ?", shared.Like(handler)).Limit(max).Find(&deductions).Error
	return deductions, err
}

func (s *DeductionInformationService) SearchByDeductionTimeRange(start time.Time, end time.Time, max int) ([]domain.DeductionInformation, error) {
	var deductions []domain.DeductionInformation
	err := s.DB().Where("deduction_time BETWEEN ? AND ?", start, end).Limit(max).Find(&deductions).Error
	return deductions, err
}

func (s *DeductionInformationService) FilterForRequester(username string, elevated bool, deductions []domain.DeductionInformation) []domain.DeductionInformation {
	if elevated {
		return deductions
	}
	driverID, ok := shared.RequesterDriverID(s.DB(), username)
	if !ok {
		return []domain.DeductionInformation{}
	}
	out := make([]domain.DeductionInformation, 0, len(deductions))
	for _, item := range deductions {
		if item.DriverID == driverID {
			out = append(out, item)
		}
	}
	return out
}

func (s *DeductionInformationService) CanAccess(username string, elevated bool, deduction *domain.DeductionInformation) bool {
	if deduction == nil {
		return false
	}
	if elevated {
		return true
	}
	driverID, ok := shared.RequesterDriverID(s.DB(), username)
	return ok && deduction.DriverID == driverID
}

func (s *DeductionInformationService) ListForRequester(username string, elevated bool) ([]domain.DeductionInformation, error) {
	if elevated {
		return s.GetAllDeductions()
	}
	driverID, ok := shared.RequesterDriverID(s.DB(), username)
	if !ok {
		return []domain.DeductionInformation{}, nil
	}
	var deductions []domain.DeductionInformation
	err := s.DB().Where("driver_id = ?", driverID).Find(&deductions).Error
	return deductions, err
}
