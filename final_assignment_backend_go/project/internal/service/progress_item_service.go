package service

import (
	"final_assignment_front_go/project/internal/domain"
	"final_assignment_front_go/project/internal/repo"
)

type ProgressItemService struct {
	repo *repo.ProgressItemRepo
}

func NewProgressItemService(repo *repo.ProgressItemRepo) *ProgressItemService {
	return &ProgressItemService{repo: repo}
}

func (s *ProgressItemService) CreateItem(item *domain.ProgressItem) error {
	return s.repo.Create(item)
}
