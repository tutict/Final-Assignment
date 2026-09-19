package service

import (
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
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

func (s *PermissionManagementService) DB() *gorm.DB { return s.repo.DB() }

func (s *PermissionManagementService) CheckAndInsertIdempotency(key string, permission *domain.PermissionManagement, operation string) error {
	if err := checkIdempotency(key, "permission:"+operation); err != nil {
		return err
	}
	now := time.Now()
	if strings.EqualFold(operation, "create") {
		if strings.TrimSpace(permission.PermissionCode) == "" {
			permission.PermissionCode = strings.ToLower(strings.ReplaceAll(permission.PermissionName, " ", ":"))
		}
		if strings.TrimSpace(permission.PermissionType) == "" {
			permission.PermissionType = "Menu"
		}
		if strings.TrimSpace(permission.Status) == "" {
			permission.Status = "Active"
		}
		permission.CreatedTime = timePtr(now)
		permission.ModifiedTime = timePtr(now)
		return s.DB().Create(permission).Error
	}
	permission.ModifiedTime = timePtr(now)
	return s.DB().Save(permission).Error
}

func (s *PermissionManagementService) GetPermissionById(id int) (*domain.PermissionManagement, error) {
	var permission domain.PermissionManagement
	err := s.DB().Where("permission_id = ?", id).First(&permission).Error
	return &permission, err
}

func (s *PermissionManagementService) GetAllPermissions() ([]domain.PermissionManagement, error) {
	return s.repo.FindAll()
}

func (s *PermissionManagementService) GetPermissionByName(name string) (*domain.PermissionManagement, error) {
	var permission domain.PermissionManagement
	err := s.DB().Where("permission_name = ?", name).First(&permission).Error
	return &permission, err
}

func (s *PermissionManagementService) GetPermissionsByNameLike(name string) ([]domain.PermissionManagement, error) {
	var permissions []domain.PermissionManagement
	err := s.DB().Where("permission_name LIKE ?", like(name)).Find(&permissions).Error
	return permissions, err
}

func (s *PermissionManagementService) UpdatePermission(id int, key string, permission *domain.PermissionManagement) error {
	permission.PermissionID = id
	return s.CheckAndInsertIdempotency(key, permission, "update")
}

func (s *PermissionManagementService) DeletePermission(id int) error {
	return s.DB().Where("permission_id = ?", id).Delete(&domain.PermissionManagement{}).Error
}

func (s *PermissionManagementService) DeletePermissionByName(name string) error {
	return s.DB().Where("permission_name = ?", name).Delete(&domain.PermissionManagement{}).Error
}
