package service

import (
	"strconv"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"

	"gorm.io/gorm"
)

func (s *BackupRestoreService) DB() *gorm.DB { return s.repo.DB() }

func (s *BackupRestoreService) CheckAndInsertIdempotency(key string, backup *domain.BackupRestore, operation string) error {
	if err := checkIdempotency(key, "backup:"+operation); err != nil {
		return err
	}
	if strings.EqualFold(operation, "create") {
		if backup.BackupTime.IsZero() {
			backup.BackupTime = time.Now()
		}
		return s.DB().Create(backup).Error
	}
	return s.DB().Save(backup).Error
}

func (s *BackupRestoreService) GetAllBackups() ([]domain.BackupRestore, error) {
	return s.repo.FindAll()
}
func (s *BackupRestoreService) GetBackupById(id string) (*domain.BackupRestore, error) {
	parsed, err := parseID(id)
	if err != nil {
		return nil, err
	}
	var backup domain.BackupRestore
	err = s.DB().Where("backup_id = ?", parsed).First(&backup).Error
	return &backup, err
}
func (s *BackupRestoreService) DeleteBackup(id string) error {
	parsed, err := parseID(id)
	if err != nil {
		return err
	}
	return s.DB().Where("backup_id = ?", parsed).Delete(&domain.BackupRestore{}).Error
}
func (s *BackupRestoreService) GetBackupByFileName(name string) (*domain.BackupRestore, error) {
	var backup domain.BackupRestore
	err := s.DB().Where("backup_file_name = ?", name).First(&backup).Error
	return &backup, err
}
func (s *BackupRestoreService) GetBackupsByTime(t time.Time) ([]domain.BackupRestore, error) {
	var backups []domain.BackupRestore
	err := s.DB().Where("DATE(backup_time) = DATE(?)", t).Find(&backups).Error
	return backups, err
}

func (s *DeductionInformationService) DB() *gorm.DB { return s.repo.DB() }

func (s *DeductionInformationService) CheckAndInsertIdempotency(key string, deduction *domain.DeductionInformation, operation string) error {
	if err := checkIdempotency(key, "deduction:"+operation); err != nil {
		return err
	}
	if strings.EqualFold(operation, "create") {
		if deduction.DeductionTime.IsZero() {
			deduction.DeductionTime = time.Now()
		}
		return s.DB().Create(deduction).Error
	}
	return s.DB().Save(deduction).Error
}

func (s *DeductionInformationService) GetDeductionById(id string) (*domain.DeductionInformation, error) {
	parsed, err := parseID(id)
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
	parsed, err := parseID(id)
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
	err := s.DB().Where("handler LIKE ?", like(handler)).Limit(max).Find(&deductions).Error
	return deductions, err
}
func (s *DeductionInformationService) SearchByDeductionTimeRange(start time.Time, end time.Time, max int) ([]domain.DeductionInformation, error) {
	var deductions []domain.DeductionInformation
	err := s.DB().Where("deduction_time BETWEEN ? AND ?", start, end).Limit(max).Find(&deductions).Error
	return deductions, err
}

func (s *FineInformationService) DB() *gorm.DB { return s.repo.DB() }

func (s *FineInformationService) CheckAndInsertIdempotency(key string, fine *domain.FineInformation, operation string) error {
	if err := checkIdempotency(key, "fine:"+operation); err != nil {
		return err
	}
	if strings.EqualFold(operation, "create") {
		if fine.FineTime.IsZero() {
			fine.FineTime = time.Now()
		}
		return s.DB().Create(fine).Error
	}
	return s.DB().Save(fine).Error
}

func (s *FineInformationService) GetFineByID(id string) (*domain.FineInformation, error) {
	parsed, err := parseID(id)
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
	parsed, err := parseID(id)
	if err != nil {
		return err
	}
	return s.DB().Where("fine_id = ?", parsed).Delete(&domain.FineInformation{}).Error
}
func (s *FineInformationService) GetFinesByPayee(payee string) ([]domain.FineInformation, error) {
	var fines []domain.FineInformation
	err := s.DB().Where("payee LIKE ?", like(payee)).Find(&fines).Error
	return fines, err
}
func (s *FineInformationService) GetFinesByTimeRange(start time.Time, end time.Time) ([]domain.FineInformation, error) {
	var fines []domain.FineInformation
	err := s.DB().Where("fine_time BETWEEN ? AND ?", start, end).Find(&fines).Error
	return fines, err
}
func (s *FineInformationService) GetFineByReceiptNumber(receipt string) (*domain.FineInformation, error) {
	var fine domain.FineInformation
	err := s.DB().Where("receipt_number = ?", receipt).First(&fine).Error
	return &fine, err
}
func (s *FineInformationService) SearchByFineTimeRange(start time.Time, end time.Time, maxSuggestions string) ([]domain.FineInformation, error) {
	max, _ := strconv.Atoi(maxSuggestions)
	if max <= 0 {
		max = 10
	}
	var fines []domain.FineInformation
	err := s.DB().Where("fine_time BETWEEN ? AND ?", start, end).Limit(max).Find(&fines).Error
	return fines, err
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

func (s *OffenseInformationService) DB() *gorm.DB { return s.repo.DB() }

func (s *OffenseInformationService) CheckAndInsertIdempotency(key string, offense *domain.OffenseInformation, operation string) error {
	if err := checkIdempotency(key, "offense:"+operation); err != nil {
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
	return &offense, err
}
func (s *OffenseInformationService) GetAllOffenses() ([]domain.OffenseInformation, error) {
	return s.repo.FindAll()
}
func (s *OffenseInformationService) DeleteOffense(id int) error {
	return s.DB().Where("offense_id = ?", id).Delete(&domain.OffenseInformation{}).Error
}
func (s *OffenseInformationService) GetOffensesByTimeRange(start time.Time, end time.Time) ([]domain.OffenseInformation, error) {
	var offenses []domain.OffenseInformation
	err := s.DB().Where("offense_time BETWEEN ? AND ?", start, end).Find(&offenses).Error
	return offenses, err
}
func (s *OffenseInformationService) SearchByOffenseType(query string, page int, size int) ([]domain.OffenseInformation, error) {
	return s.searchOffenses("offense_type", query, page, size)
}
func (s *OffenseInformationService) SearchByDriverName(query string, page int, size int) ([]domain.OffenseInformation, error) {
	return s.searchOffenses("driver_name", query, page, size)
}
func (s *OffenseInformationService) SearchByLicensePlate(query string, page int, size int) ([]domain.OffenseInformation, error) {
	return s.searchOffenses("license_plate", query, page, size)
}
func (s *OffenseInformationService) searchOffenses(column string, query string, page int, size int) ([]domain.OffenseInformation, error) {
	offset, limit := pageBounds(page, size)
	var offenses []domain.OffenseInformation
	err := s.DB().Where(column+" LIKE ?", like(query)).Offset(offset).Limit(limit).Find(&offenses).Error
	return offenses, err
}
