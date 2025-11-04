package service

import (
	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"
)

type SystemLogsService struct {
	repo *repo.SystemLogsRepo
}

func NewSystemLogsService(repo *repo.SystemLogsRepo) *SystemLogsService {
	return &SystemLogsService{repo: repo}
}

func (s *SystemLogsService) CreateLog(log *domain.SystemLogs) error {
	return s.repo.Create(log)
}
