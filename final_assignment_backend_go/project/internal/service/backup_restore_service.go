package service

import (
	"final_assignment_front_go/project/internal/domain"
	"final_assignment_front_go/project/internal/repo"
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
