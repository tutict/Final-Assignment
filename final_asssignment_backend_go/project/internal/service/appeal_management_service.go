package service

import (
	"final_asssignment_front_go/project/internal/domain"
	"final_asssignment_front_go/project/internal/repo"
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
