package service

import (
	"final_asssignment_front_go/project/internal/domain"
	"final_asssignment_front_go/project/internal/repo"
)

type VehicleInformationService struct {
	repo *repo.VehicleInformationRepo
}

func NewVehicleInformationService(repo *repo.VehicleInformationRepo) *VehicleInformationService {
	return &VehicleInformationService{repo: repo}
}

func (s *VehicleInformationService) CreateVehicle(vehicle *domain.VehicleInformation) error {
	return s.repo.Create(vehicle)
}

func (s *VehicleInformationService) GetVehicleByID(id int) (*domain.VehicleInformation, error) {
	return s.repo.FindByID(id)
}

func (s *VehicleInformationService) UpdateVehicle(vehicle *domain.VehicleInformation) error {
	return s.repo.Update(vehicle)
}

func (s *VehicleInformationService) DeleteVehicle(id int) error {
	return s.repo.Delete(id)
}
