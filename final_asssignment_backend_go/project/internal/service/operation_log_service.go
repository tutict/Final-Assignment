package service

import (
	"final_asssignment_front_go/project/internal/domain"
	"final_asssignment_front_go/project/internal/repo"
)

type OperationLogService struct {
	repo *repo.OperationLogRepo
}

func NewOperationLogService(repo *repo.OperationLogRepo) *OperationLogService {
	return &OperationLogService{repo: repo}
}

func (s *OperationLogService) CreateLog(log *domain.OperationLog) error {
	return s.repo.Create(log)
}
