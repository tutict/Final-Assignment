package service

import (
	"final_assignment_front_go/project/internal/domain"
	"final_assignment_front_go/project/internal/repo"
)

type OffenseDetailsService struct {
	repo *repo.OffenseDetailsRepo
}

func NewOffenseDetailsService(repo *repo.OffenseDetailsRepo) *OffenseDetailsService {
	return &OffenseDetailsService{repo: repo}
}

func (s *OffenseDetailsService) CreateOffense(offense *domain.OffenseDetails) error {
	return s.repo.Create(offense)
}
