package service

import (
	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"
)

type SystemSettingsService struct {
	repo *repo.SystemSettingsRepo
}

func NewSystemSettingsService(repo *repo.SystemSettingsRepo) *SystemSettingsService {
	return &SystemSettingsService{repo: repo}
}

func (s *SystemSettingsService) CreateSettings(settings *domain.SystemSettings) error {
	return s.repo.Create(settings)
}
