package admin

import (
	"final_assignment_backend_go/project/internal/service/shared"
	"fmt"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
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

func (s *UserManagementService) DB() *gorm.DB {
	return s.repo.DB()
}

func (s *UserManagementService) IsUsernameExists(username string) bool {
	var count int64
	s.DB().Model(&domain.UserManagement{}).Where("username = ?", strings.TrimSpace(username)).Count(&count)
	return count > 0
}

func (s *UserManagementService) CheckAndInsertIdempotency(key string, user *domain.UserManagement, operation string) error {
	if err := shared.CheckIdempotency(key, operation); err != nil {
		return err
	}
	now := time.Now()
	switch strings.ToLower(operation) {
	case "create":
		if user.CreatedTime == nil {
			user.CreatedTime = shared.TimePtr(now)
		}
		user.ModifiedTime = shared.TimePtr(now)
		if user.Status == "" {
			user.Status = "Active"
		}
		if user.Password != "" && !strings.HasPrefix(user.Password, "$2") {
			hashed, err := shared.HashPassword(user.Password)
			if err != nil {
				return err
			}
			user.Password = hashed
		}
		return s.DB().Create(user).Error
	case "update":
		user.ModifiedTime = shared.TimePtr(now)
		if user.Password != "" && !strings.HasPrefix(user.Password, "$2") {
			hashed, err := shared.HashPassword(user.Password)
			if err != nil {
				return err
			}
			user.Password = hashed
		}
		return s.DB().Save(user).Error
	default:
		return fmt.Errorf("unsupported operation: %s", operation)
	}
}

func (s *UserManagementService) GetAllUsers() ([]domain.UserManagement, error) {
	return s.repo.FindAll()
}

func (s *UserManagementService) GetUserByID(userID string) (*domain.UserManagement, error) {
	id, err := shared.ParseID(userID)
	if err != nil {
		return nil, err
	}
	return s.GetUserById(id)
}

func (s *UserManagementService) GetUserById(userID int) (*domain.UserManagement, error) {
	var user domain.UserManagement
	err := s.DB().Where("user_id = ?", userID).First(&user).Error
	return &user, err
}

func (s *UserManagementService) GetUserByUsername(username string) (*domain.UserManagement, error) {
	var user domain.UserManagement
	err := s.DB().Where("username = ?", strings.TrimSpace(username)).First(&user).Error
	return &user, err
}

func (s *UserManagementService) GetUsersByRole(roleName string) ([]domain.UserManagement, error) {
	var users []domain.UserManagement
	err := s.DB().Table("sys_user").
		Joins("JOIN sys_user_role ON sys_user_role.user_id = sys_user.user_id AND sys_user_role.deleted_at IS NULL").
		Joins("JOIN sys_role ON sys_role.role_id = sys_user_role.role_id AND sys_role.deleted_at IS NULL").
		Where("(sys_role.role_name = ? OR sys_role.role_code = ?) AND sys_user.deleted_at IS NULL", roleName, roleName).
		Find(&users).Error
	return users, err
}

func (s *UserManagementService) GetUsersByStatus(status string) ([]domain.UserManagement, error) {
	var users []domain.UserManagement
	err := s.DB().Where("status = ?", status).Find(&users).Error
	return users, err
}

func (s *UserManagementService) UpdateUserByID(userID string, updated *domain.UserManagement, key string) error {
	id, err := shared.ParseID(userID)
	if err != nil {
		return err
	}
	updated.UserID = id
	return s.CheckAndInsertIdempotency(key, updated, "update")
}

func (s *UserManagementService) UpdateUser(user *domain.UserManagement) error {
	user.ModifiedTime = shared.TimePtr(time.Now())
	return s.DB().Save(user).Error
}

func (s *UserManagementService) DeleteUserByID(userID string) error {
	id, err := shared.ParseID(userID)
	if err != nil {
		return err
	}
	return s.DB().Where("user_id = ?", id).Delete(&domain.UserManagement{}).Error
}

func (s *UserManagementService) DeleteUserByUsername(username string) error {
	return s.DB().Where("username = ?", username).Delete(&domain.UserManagement{}).Error
}

func (s *UserManagementService) GetUsernamesByPrefixGlobally(prefix string) ([]string, error) {
	return shared.DistinctStrings(s.DB(), "sys_user", "username", prefix, 10), nil
}

func (s *UserManagementService) GetStatusesByPrefixGlobally(prefix string) ([]string, error) {
	return shared.DistinctStrings(s.DB(), "sys_user", "status", prefix, 10), nil
}

func (s *UserManagementService) GetPhoneNumbersByPrefixGlobally(prefix string) ([]string, error) {
	return shared.DistinctStrings(s.DB(), "sys_user", "contact_number", prefix, 10), nil
}

func (s *UserManagementService) GetRoleNamesForUser(userID int) ([]string, error) {
	var roles []string
	err := s.DB().Table("sys_role").
		Select("sys_role.role_code").
		Joins("JOIN sys_user_role ON sys_user_role.role_id = sys_role.role_id AND sys_user_role.deleted_at IS NULL").
		Where("sys_user_role.user_id = ? AND sys_role.deleted_at IS NULL", userID).
		Pluck("sys_role.role_code", &roles).Error
	return roles, err
}
