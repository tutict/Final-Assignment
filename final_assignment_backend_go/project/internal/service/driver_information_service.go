package service

import (
	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"
)

type DriverInformationService struct {
	repo *repo.DriverInformationRepo
}

func NewDriverInformationService(repo *repo.DriverInformationRepo) *DriverInformationService {
	return &DriverInformationService{repo: repo}
}

func (s *DriverInformationService) CreateDriver(driver *domain.DriverInformation) error {
	return s.repo.Create(driver)
}
