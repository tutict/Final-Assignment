package service

import (
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
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

func (s *RoleManagementService) DB() *gorm.DB { return s.repo.DB() }

func (s *RoleManagementService) CheckAndInsertIdempotency(key string, role *domain.RoleManagement, operation string) error {
	if err := checkIdempotency(key, "role:"+operation); err != nil {
		return err
	}
	now := time.Now()
	if strings.EqualFold(operation, "create") {
		if strings.TrimSpace(role.RoleCode) == "" {
			role.RoleCode = strings.ToUpper(strings.ReplaceAll(role.RoleName, " ", "_"))
		}
		if strings.TrimSpace(role.RoleType) == "" {
			role.RoleType = "Business"
		}
		if strings.TrimSpace(role.DataScope) == "" {
			role.DataScope = "Self"
		}
		if strings.TrimSpace(role.Status) == "" {
			role.Status = "Active"
		}
		role.CreatedTime = timePtr(now)
		role.ModifiedTime = timePtr(now)
		return s.DB().Create(role).Error
	}
	role.ModifiedTime = timePtr(now)
	return s.DB().Save(role).Error
}

func (s *RoleManagementService) GetRoleById(id string) (*domain.RoleManagement, error) {
	parsed, err := parseID(id)
	if err != nil {
		return nil, err
	}
	var role domain.RoleManagement
	err = s.DB().Where("role_id = ?", parsed).First(&role).Error
	return &role, err
}

func (s *RoleManagementService) GetAllRoles() ([]domain.RoleManagement, error) {
	return s.repo.FindAll()
}

func (s *RoleManagementService) GetRoleByName(name string) (*domain.RoleManagement, error) {
	var role domain.RoleManagement
	err := s.DB().Where("role_name = ?", name).First(&role).Error
	return &role, err
}

func (s *RoleManagementService) GetRolesByNameLike(name string) ([]domain.RoleManagement, error) {
	var roles []domain.RoleManagement
	err := s.DB().Where("role_name LIKE ?", like(name)).Find(&roles).Error
	return roles, err
}

func (s *RoleManagementService) DeleteRole(id string) error {
	parsed, err := parseID(id)
	if err != nil {
		return err
	}
	return s.DB().Where("role_id = ?", parsed).Delete(&domain.RoleManagement{}).Error
}

func (s *RoleManagementService) DeleteRoleByName(name string) error {
	return s.DB().Where("role_name = ?", name).Delete(&domain.RoleManagement{}).Error
}
