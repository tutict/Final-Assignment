package service

import (
	"final_asssignment_front_go/project/internal/domain"
	"final_asssignment_front_go/project/internal/repo"
)

type RoleManagementService struct {
	repo *repo.RoleManagementRepo
}

func NewRoleManagementService(repo *repo.RoleManagementRepo) *RoleManagementService {
	return &RoleManagementService{repo: repo}
}

func (s *RoleManagementService) CreateRole(role *domain.RoleManagement) error {
	return s.repo.Create(role)
}
