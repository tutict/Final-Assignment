package service

import (
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	authcfg "final_assignment_backend_go/project/configs/auth"
	"final_assignment_backend_go/project/internal/domain"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type RegisterRequest struct {
	Username      string `json:"username"`
	Password      string `json:"password"`
	ContactNumber string `json:"contactNumber"`
	Email         string `json:"email"`
}

type AuthWsService struct {
	users             *UserManagementService
	tokenProvider     *authcfg.TokenProvider
	loginGuard        sync.Mutex
	failedAttempts    map[string]int
	lockedUntilByUser map[string]time.Time
}

func NewAuthWsService(users *UserManagementService, tokenProvider *authcfg.TokenProvider) *AuthWsService {
	return &AuthWsService{
		users:             users,
		tokenProvider:     tokenProvider,
		failedAttempts:    map[string]int{},
		lockedUntilByUser: map[string]time.Time{},
	}
}

func (s *AuthWsService) Login(req LoginRequest) (map[string]interface{}, error) {
	username := strings.TrimSpace(req.Username)
	if err := s.rejectIfLocked(username); err != nil {
		return nil, err
	}
	user, err := s.users.GetUserByUsername(req.Username)
	if err != nil {
		s.recordFailedLogin(username)
		return nil, errors.New("invalid credentials")
	}
	if !passwordMatches(user.Password, req.Password) {
		s.recordFailedLogin(username)
		return nil, errors.New("invalid credentials")
	}
	if !isActiveUser(user.Status) {
		s.recordFailedLogin(username)
		return nil, errors.New("account is disabled")
	}
	roles, err := s.users.GetRoleNamesForUser(user.UserID)
	if err != nil || len(roles) == 0 {
		roles = []string{"USER"}
	}
	token, err := s.tokenProvider.CreateToken(user.Username, strings.Join(roles, ","))
	if err != nil {
		return nil, err
	}
	s.clearFailedLogin(username)
	return map[string]interface{}{
		"jwtToken": token,
		"username": user.Username,
		"roles":    roles,
	}, nil
}

func (s *AuthWsService) Refresh(token string) (map[string]interface{}, error) {
	username, err := s.tokenProvider.GetUsernameFromToken(token)
	if err != nil {
		return nil, err
	}
	roles, err := s.tokenProvider.ExtractRoles(token)
	if err != nil {
		return nil, err
	}
	for i, role := range roles {
		roles[i] = strings.TrimPrefix(role, "ROLE_")
	}
	newToken, err := s.tokenProvider.CreateToken(username, strings.Join(roles, ","))
	if err != nil {
		return nil, err
	}
	return map[string]interface{}{"jwtToken": newToken, "username": username, "roles": roles}, nil
}

func (s *AuthWsService) RegisterUser(req RegisterRequest) (string, error) {
	if strings.TrimSpace(req.Username) == "" || strings.TrimSpace(req.Password) == "" {
		return "", errors.New("username and password are required")
	}
	if s.users.IsUsernameExists(req.Username) {
		return "", errors.New("username already exists")
	}
	hashed, err := hashPassword(req.Password)
	if err != nil {
		return "", err
	}
	now := time.Now()
	user := &domain.UserManagement{
		Username:      strings.TrimSpace(req.Username),
		Password:      hashed,
		ContactNumber: req.ContactNumber,
		Email:         req.Email,
		Status:        "ACTIVE",
		CreatedTime:   now,
		ModifiedTime:  now,
	}
	if err := s.users.CreateUser(user); err != nil {
		return "", err
	}
	return "registered", nil
}

func (s *AuthWsService) GetAllUsers() ([]domain.UserManagement, error) {
	return s.users.GetAllUsers()
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
	if err := checkIdempotency(key, operation); err != nil {
		return err
	}
	now := time.Now()
	switch strings.ToLower(operation) {
	case "create":
		if user.CreatedTime.IsZero() {
			user.CreatedTime = now
		}
		user.ModifiedTime = now
		if user.Status == "" {
			user.Status = "ACTIVE"
		}
		if user.Password != "" && !strings.HasPrefix(user.Password, "$2") {
			hashed, err := hashPassword(user.Password)
			if err != nil {
				return err
			}
			user.Password = hashed
		}
		return s.DB().Create(user).Error
	case "update":
		user.ModifiedTime = now
		if user.Password != "" && !strings.HasPrefix(user.Password, "$2") {
			hashed, err := hashPassword(user.Password)
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
	id, err := parseID(userID)
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
	err := s.DB().Table("user_management").
		Joins("JOIN user_role ON user_role.user_id = user_management.user_id").
		Joins("JOIN role_management ON role_management.role_id = user_role.role_id").
		Where("role_management.role_name = ?", roleName).
		Find(&users).Error
	return users, err
}

func (s *UserManagementService) GetUsersByStatus(status string) ([]domain.UserManagement, error) {
	var users []domain.UserManagement
	err := s.DB().Where("status = ?", status).Find(&users).Error
	return users, err
}

func (s *UserManagementService) UpdateUserByID(userID string, updated *domain.UserManagement, key string) error {
	id, err := parseID(userID)
	if err != nil {
		return err
	}
	updated.UserID = id
	return s.CheckAndInsertIdempotency(key, updated, "update")
}

func (s *UserManagementService) UpdateUser(user *domain.UserManagement) error {
	user.ModifiedTime = time.Now()
	return s.DB().Save(user).Error
}

func (s *UserManagementService) DeleteUserByID(userID string) error {
	id, err := parseID(userID)
	if err != nil {
		return err
	}
	return s.DB().Where("user_id = ?", id).Delete(&domain.UserManagement{}).Error
}

func (s *UserManagementService) DeleteUserByUsername(username string) error {
	return s.DB().Where("username = ?", username).Delete(&domain.UserManagement{}).Error
}

func (s *UserManagementService) GetUsernamesByPrefixGlobally(prefix string) ([]string, error) {
	return distinctStrings(s.DB(), "user_management", "username", prefix, 10), nil
}

func (s *UserManagementService) GetStatusesByPrefixGlobally(prefix string) ([]string, error) {
	return distinctStrings(s.DB(), "user_management", "status", prefix, 10), nil
}

func (s *UserManagementService) GetPhoneNumbersByPrefixGlobally(prefix string) ([]string, error) {
	return distinctStrings(s.DB(), "user_management", "contact_number", prefix, 10), nil
}

func (s *UserManagementService) GetRoleNamesForUser(userID int) ([]string, error) {
	var roles []string
	err := s.DB().Table("role_management").
		Select("role_management.role_name").
		Joins("JOIN user_role ON user_role.role_id = role_management.role_id").
		Where("user_role.user_id = ?", userID).
		Pluck("role_management.role_name", &roles).Error
	return roles, err
}

func hashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

func passwordMatches(stored string, candidate string) bool {
	if stored == "" {
		return false
	}
	if strings.HasPrefix(stored, "$2") {
		return bcrypt.CompareHashAndPassword([]byte(stored), []byte(candidate)) == nil
	}
	return stored == candidate
}

func isActiveUser(status string) bool {
	if status == "" {
		return true
	}
	normalized := strings.ToUpper(strings.TrimSpace(status))
	return normalized == "ACTIVE" || normalized == "ENABLED" || normalized == "NORMAL"
}

func (s *AuthWsService) rejectIfLocked(username string) error {
	s.loginGuard.Lock()
	defer s.loginGuard.Unlock()
	until := s.lockedUntilByUser[username]
	if until.IsZero() || time.Now().After(until) {
		return nil
	}
	return errors.New("account temporarily locked")
}

func (s *AuthWsService) recordFailedLogin(username string) {
	s.loginGuard.Lock()
	defer s.loginGuard.Unlock()
	s.failedAttempts[username]++
	if s.failedAttempts[username] >= 5 {
		s.lockedUntilByUser[username] = time.Now().Add(15 * time.Minute)
	}
}

func (s *AuthWsService) clearFailedLogin(username string) {
	s.loginGuard.Lock()
	defer s.loginGuard.Unlock()
	delete(s.failedAttempts, username)
	delete(s.lockedUntilByUser, username)
}
