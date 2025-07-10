package service

import (
	"final_asssignment_front_go/project/internal/domain"
	"final_asssignment_front_go/project/internal/repo"
)

type DeductionInformationService struct {
	repo *repo.DeductionInformationRepo
}

func NewDeductionInformationService(repo *repo.DeductionInformationRepo) *DeductionInformationService {
	return &DeductionInformationService{repo: repo}
}

func (s *DeductionInformationService) CreateDeduction(deduction *domain.DeductionInformation) error {
	return s.repo.Create(deduction)
}
