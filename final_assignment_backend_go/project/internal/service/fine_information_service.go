package service

import (
	"final_assignment_front_go/project/internal/domain"
	"final_assignment_front_go/project/internal/repo"
)

type FineInformationService struct {
	repo *repo.FineInformationRepo
}

func NewFineInformationService(repo *repo.FineInformationRepo) *FineInformationService {
	return &FineInformationService{repo: repo}
}

func (s *FineInformationService) CreateFine(fine *domain.FineInformation) error {
	return s.repo.Create(fine)
}
