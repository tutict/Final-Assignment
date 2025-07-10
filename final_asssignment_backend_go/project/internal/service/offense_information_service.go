package service

import (
	"final_asssignment_front_go/project/internal/domain"
	"final_asssignment_front_go/project/internal/repo"
)

type OffenseInformationService struct {
	repo *repo.OffenseInformationRepo
}

func NewOffenseInformationService(repo *repo.OffenseInformationRepo) *OffenseInformationService {
	return &OffenseInformationService{repo: repo}
}

func (s *OffenseInformationService) CreateOffense(offense *domain.OffenseInformation) error {
	return s.repo.Create(offense)
}
