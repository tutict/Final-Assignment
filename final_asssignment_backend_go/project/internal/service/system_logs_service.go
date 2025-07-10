package service

import (
	"final_asssignment_front_go/project/internal/domain"
	"final_asssignment_front_go/project/internal/repo"
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
