package service

import (
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

type BackupRestoreService struct {
	repo *repo.BackupRestoreRepo
}

func NewBackupRestoreService(repo *repo.BackupRestoreRepo) *BackupRestoreService {
	return &BackupRestoreService{repo: repo}
}

func (s *BackupRestoreService) CreateBackup(backup *domain.BackupRestore) error {
	return s.repo.Create(backup)
}

func (s *BackupRestoreService) DB() *gorm.DB { return s.repo.DB() }

func (s *BackupRestoreService) CheckAndInsertIdempotency(key string, backup *domain.BackupRestore, operation string) error {
	if err := checkIdempotency(key, "backup:"+operation); err != nil {
		return err
	}
	if strings.EqualFold(operation, "create") {
		if backup.BackupTime.IsZero() {
			backup.BackupTime = time.Now()
		}
		if strings.TrimSpace(backup.BackupFilePath) == "" {
			backup.BackupFilePath = backup.BackupFileName
		}
		if strings.TrimSpace(backup.BackupType) == "" {
			backup.BackupType = "Full"
		}
		if strings.TrimSpace(backup.Status) == "" {
			backup.Status = "Success"
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
