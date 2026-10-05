package offense

import (
	"final_assignment_backend_go/project/internal/reliability"
	"final_assignment_backend_go/project/internal/service/shared"
	"fmt"
	"strconv"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

type FineInformationService struct {
	repo *repo.FineInformationRepo
}

func NewFineInformationService(repo *repo.FineInformationRepo) *FineInformationService {
	return &FineInformationService{repo: repo}
}

func (s *FineInformationService) CreateFine(fine *domain.FineInformation) error {
	return s.repo.Create(fine)
}

func (s *FineInformationService) DB() *gorm.DB { return s.repo.DB() }

func (s *FineInformationService) CheckAndInsertIdempotency(key string, fine *domain.FineInformation, operation string) error {
	if strings.EqualFold(operation, "create") && (fine == nil || fine.OffenseID <= 0) {
		return fmt.Errorf("请选择关联的违法记录")
	}
	driverID := 0
	if fine.DriverID != nil {
		driverID = *fine.DriverID
	}
	fingerprint := reliability.Fingerprint(fmt.Sprintf("%d|%d|%v|%s", fine.OffenseID, driverID, fine.FineAmount, fine.PaymentStatus))
	method, url := "POST", "/api/fines"
	if !strings.EqualFold(operation, "create") {
		method = "PUT"
		url = "/api/fines/" + strconv.Itoa(fine.FineID)
	}
	if err := reliability.Reserve(s.DB(), key, "FINE_"+strings.ToUpper(operation), method, url, fingerprint, nil); err != nil {
		return err
	}
	if strings.EqualFold(operation, "create") {
		if fine.FineDate == nil {
			fine.FineDate = shared.TimePtr(time.Now())
		}
		if strings.TrimSpace(fine.FineNumber) == "" {
			fine.FineNumber = "FN" + time.Now().Format("20060102150405")
		}
		if strings.TrimSpace(fine.PaymentStatus) == "" {
			if strings.TrimSpace(fine.Status) != "" {
				fine.PaymentStatus = fine.Status
			} else {
				fine.PaymentStatus = "Unpaid"
			}
		}
		if strings.TrimSpace(fine.IssuingAuthority) == "" {
			fine.IssuingAuthority = "系统"
		}
		if strings.TrimSpace(fine.Handler) == "" {
			fine.Handler = "system"
		}
		if fine.TotalAmount == 0 {
			fine.TotalAmount = fine.FineAmount + fine.LateFee
		}
		if fine.UnpaidAmount == 0 && fine.PaymentStatus != "Paid" {
			fine.UnpaidAmount = fine.TotalAmount
		}
		db := reliability.Ledger(s.DB())
		err := db.Create(fine).Error
		return reliability.Finish(db, key, int64(fine.FineID), err)
	}
	db := reliability.Ledger(s.DB())
	return reliability.Finish(db, key, int64(fine.FineID), db.Save(fine).Error)
}

func (s *FineInformationService) GetFineByID(id string) (*domain.FineInformation, error) {
	parsed, err := shared.ParseID(id)
	if err != nil {
		return nil, err
	}
	var fine domain.FineInformation
	err = s.DB().Where("fine_id = ?", parsed).First(&fine).Error
	return &fine, err
}

func (s *FineInformationService) GetAllFines() ([]domain.FineInformation, error) {
	return s.repo.FindAll()
}

func (s *FineInformationService) DeleteFine(id string) error {
	parsed, err := shared.ParseID(id)
	if err != nil {
		return err
	}
	return s.DB().Where("fine_id = ?", parsed).Delete(&domain.FineInformation{}).Error
}

func (s *FineInformationService) GetFinesByPayee(payee string) ([]domain.FineInformation, error) {
	var fines []domain.FineInformation
	err := s.DB().Where("handler LIKE ?", shared.Like(payee)).Find(&fines).Error
	return fines, err
}

func (s *FineInformationService) GetFinesByTimeRange(start time.Time, end time.Time) ([]domain.FineInformation, error) {
	var fines []domain.FineInformation
	err := s.DB().Where("fine_date BETWEEN ? AND ?", start, end).Find(&fines).Error
	return fines, err
}

func (s *FineInformationService) GetFineByReceiptNumber(receipt string) (*domain.FineInformation, error) {
	var fine domain.FineInformation
	err := s.DB().Where("fine_number = ?", receipt).First(&fine).Error
	return &fine, err
}

func (s *FineInformationService) SearchByFineTimeRange(start time.Time, end time.Time, maxSuggestions string) ([]domain.FineInformation, error) {
	max, _ := strconv.Atoi(maxSuggestions)
	if max <= 0 {
		max = 10
	}
	var fines []domain.FineInformation
	err := s.DB().Where("fine_date BETWEEN ? AND ?", start, end).Limit(max).Find(&fines).Error
	return fines, err
}

func (s *FineInformationService) GetFinesByDriverID(driverID int) ([]domain.FineInformation, error) {
	var fines []domain.FineInformation
	err := s.DB().Where("driver_id = ?", driverID).Find(&fines).Error
	return fines, err
}

func (s *FineInformationService) GetFinesByOffenseID(offenseID int) ([]domain.FineInformation, error) {
	var fines []domain.FineInformation
	err := s.DB().Where("offense_id = ?", offenseID).Find(&fines).Error
	return fines, err
}

func (s *FineInformationService) SearchByPaymentStatus(status string, page int, size int) ([]domain.FineInformation, error) {
	offset, limit := shared.PageBounds(page, size)
	var fines []domain.FineInformation
	err := s.DB().Where("payment_status = ?", status).Offset(offset).Limit(limit).Find(&fines).Error
	return fines, err
}

func (s *FineInformationService) FilterForRequester(username string, elevated bool, fines []domain.FineInformation) []domain.FineInformation {
	if elevated {
		return fines
	}
	driverID, ok := shared.RequesterDriverID(s.DB(), username)
	if !ok {
		return []domain.FineInformation{}
	}
	out := make([]domain.FineInformation, 0, len(fines))
	for _, fine := range fines {
		if fine.DriverID != nil && *fine.DriverID == driverID {
			out = append(out, fine)
		}
	}
	return out
}

func (s *FineInformationService) CanAccess(username string, elevated bool, fine *domain.FineInformation) bool {
	if fine == nil {
		return false
	}
	if elevated {
		return true
	}
	driverID, ok := shared.RequesterDriverID(s.DB(), username)
	return ok && fine.DriverID != nil && *fine.DriverID == driverID
}

func (s *FineInformationService) ListForRequester(username string, elevated bool) ([]domain.FineInformation, error) {
	if elevated {
		return s.GetAllFines()
	}
	driverID, ok := shared.RequesterDriverID(s.DB(), username)
	if !ok {
		return []domain.FineInformation{}, nil
	}
	return s.GetFinesByDriverID(driverID)
}
