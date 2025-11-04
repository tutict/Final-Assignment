package service

import (
	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"
)

type RequestHistoryService struct {
	repo *repo.RequestHistoryRepo
}

func NewRequestHistoryService(repo *repo.RequestHistoryRepo) *RequestHistoryService {
	return &RequestHistoryService{repo: repo}
}

func (s *RequestHistoryService) CreateHistory(history *domain.RequestHistory) error {
	return s.repo.Create(history)
}
