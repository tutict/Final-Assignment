package service

import (
	"final_asssignment_front_go/project/internal/domain"
	"final_asssignment_front_go/project/internal/repo"
)

type PermissionManagementService struct {
	repo *repo.PermissionManagementRepo
}

func NewPermissionManagementService(repo *repo.PermissionManagementRepo) *PermissionManagementService {
	return &PermissionManagementService{repo: repo}
}

func (s *PermissionManagementService) CreatePermission(permission *domain.PermissionManagement) error {
	return s.repo.Create(permission)
}
