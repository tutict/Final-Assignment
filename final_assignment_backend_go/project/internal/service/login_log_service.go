package service

import (
	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"
)

type LoginLogService struct {
	repo *repo.LoginLogRepo
}

func NewLoginLogService(repo *repo.LoginLogRepo) *LoginLogService {
	return &LoginLogService{repo: repo}
}

func (s *LoginLogService) CreateLog(log *domain.LoginLog) error {
	return s.repo.Create(log)
}
