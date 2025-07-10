package service

import (
	"final_asssignment_front_go/project/internal/domain"
	"final_asssignment_front_go/project/internal/repo"
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
