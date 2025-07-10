package service

import (
	"final_asssignment_front_go/project/internal/domain"
	"final_asssignment_front_go/project/internal/repo"
)

type UserManagementService struct {
	repo *repo.UserManagementRepo
}

func NewUserManagementService(repo *repo.UserManagementRepo) *UserManagementService {
	return &UserManagementService{repo: repo}
}

func (s *UserManagementService) CreateUser(user *domain.UserManagement) error {
	return s.repo.Create(user)
}
