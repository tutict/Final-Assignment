package auth

import (
	"errors"
	"final_assignment_backend_go/project/internal/service/admin"
	"final_assignment_backend_go/project/internal/service/shared"
	"fmt"
	"strings"
	"sync"
	"time"

	authcfg "final_assignment_backend_go/project/configs/auth"
	"final_assignment_backend_go/project/internal/domain"

	"golang.org/x/crypto/bcrypt"
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

const RegisterStatusCreated = "CREATED"

type AuthWsService struct {
	users             *admin.UserManagementService
	tokenProvider     *authcfg.TokenProvider
	refreshTokens     *RefreshTokenService
	blacklist         *TokenBlacklistService
	loginGuard        sync.Mutex
	failedAttempts    map[string]int
	lockedUntilByUser map[string]time.Time
}

func NewAuthWsService(users *admin.UserManagementService, tokenProvider *authcfg.TokenProvider) *AuthWsService {
	return &AuthWsService{
		users:             users,
		tokenProvider:     tokenProvider,
		failedAttempts:    map[string]int{},
		lockedUntilByUser: map[string]time.Time{},
	}
}

func (s *AuthWsService) SetRefreshTokenService(r *RefreshTokenService) { s.refreshTokens = r }

// SetTokenBlacklistService 注入 access token 黑名单服务（可选；未注入时 Logout 不撤销）。

func (s *AuthWsService) SetTokenBlacklistService(b *TokenBlacklistService) { s.blacklist = b }

type authAccount struct {
	UserID        uint64
	Username      string
	Password      string
	Status        string
	Email         string
	ContactNumber string
}

type sysUserRow struct {
	UserID        uint64 `gorm:"column:user_id"`
	Username      string `gorm:"column:username"`
	Password      string `gorm:"column:password"`
	Status        string `gorm:"column:status"`
	Email         string `gorm:"column:email"`
	ContactNumber string `gorm:"column:contact_number"`
}

func accountFromSysUser(row sysUserRow) *authAccount {
	return &authAccount{
		UserID:        row.UserID,
		Username:      row.Username,
		Password:      row.Password,
		Status:        row.Status,
		Email:         row.Email,
		ContactNumber: row.ContactNumber,
	}
}

func accountFromUserManagement(user *domain.UserManagement) *authAccount {
	return &authAccount{
		UserID:        uint64(user.UserID),
		Username:      user.Username,
		Password:      user.Password,
		Status:        user.Status,
		Email:         user.Email,
		ContactNumber: user.ContactNumber,
	}
}

func (s *AuthWsService) lookupSysUser(query string, args ...interface{}) (*authAccount, error) {
	var row sysUserRow
	err := s.users.DB().Table("sys_user").Where(query, args...).Take(&row).Error
	if err != nil {
		return nil, err
	}
	return accountFromSysUser(row), nil
}

func (s *AuthWsService) lookupAuthAccount(username string) (*authAccount, error) {
	if account, err := s.lookupSysUser("username = ? AND deleted_at IS NULL", username); err == nil {
		return account, nil
	}
	user, err := s.users.GetUserByUsername(username)
	if err != nil {
		return nil, err
	}
	return accountFromUserManagement(user), nil
}

func (s *AuthWsService) lookupAuthAccountByID(userID uint64) (*authAccount, error) {
	if account, err := s.lookupSysUser("user_id = ? AND deleted_at IS NULL", userID); err == nil {
		return account, nil
	}
	user, err := s.users.GetUserById(int(userID))
	if err != nil {
		return nil, err
	}
	return accountFromUserManagement(user), nil
}

func (s *AuthWsService) lookupAuthRoles(account *authAccount) []string {
	var roles []string
	_ = s.users.DB().Table("sys_role").
		Select("sys_role.role_code").
		Joins("JOIN sys_user_role ON sys_user_role.role_id = sys_role.role_id AND sys_user_role.deleted_at IS NULL").
		Where("sys_user_role.user_id = ? AND sys_role.deleted_at IS NULL", account.UserID).
		Pluck("sys_role.role_code", &roles).Error
	if len(roles) > 0 {
		return roles
	}
	legacy, err := s.users.GetRoleNamesForUser(int(account.UserID))
	if err != nil || len(legacy) == 0 {
		return []string{"USER"}
	}
	return legacy
}

func (s *AuthWsService) Login(req LoginRequest) (map[string]interface{}, error) {
	username := strings.TrimSpace(req.Username)
	if err := s.rejectIfLocked(username); err != nil {
		return nil, err
	}
	user, err := s.lookupAuthAccount(req.Username)
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
	roles := s.lookupAuthRoles(user)
	token, err := s.tokenProvider.CreateToken(user.Username, strings.Join(roles, ","))
	if err != nil {
		return nil, err
	}
	driverID, driverName := s.lookupDriverProfile(user.UserID)
	result := map[string]interface{}{
		"jwtToken":    token,
		"accessToken": token,
		"tokenType":   "Bearer",
		"expiresIn":   s.tokenProvider.GetAccessTokenExpirationSeconds(),
		"username":    user.Username,
		"roles":       roles,
		"driverId":    driverID,
		"driverName":  driverName,
	}
	// 若注入了刷新令牌服务，则签发独立的 refresh token（与 Spring/Quarkus 对齐）。
	// 签发失败不应静默吞掉：否则客户端拿到无 refreshToken 的 200，无法区分"未启用 refresh"与
	// "签发失败"，access token 过期后只能被迫重登。Spring/Quarkus 的 Login 不 try/catch，失败即 500。
	if s.refreshTokens != nil {
		refresh, rerr := s.refreshTokens.CreateRefreshToken(user.UserID)
		if rerr != nil {
			return nil, fmt.Errorf("issue refresh token: %w", rerr)
		}
		result["refreshToken"] = refresh
		result["refreshTokenExpiresIn"] = s.refreshTokens.GetRefreshTokenExpirationSeconds()
	}
	s.clearFailedLogin(username)
	return result, nil
}

func (s *AuthWsService) Refresh(token string) (map[string]interface{}, error) {
	// 优先走持久化 refresh token 流程（与 Spring/Quarkus 对齐）：
	// 用原始 refresh token 换取新的 access token，并轮换 refresh token（旧的即刻失效）。
	if s.refreshTokens != nil {
		userID, err := s.refreshTokens.ValidateRefreshToken(token)
		if err != nil {
			return nil, err
		}
		user, uerr := s.lookupAuthAccountByID(userID)
		if uerr != nil {
			return nil, errors.New("refresh token user no longer exists")
		}
		roles := s.lookupAuthRoles(user)
		newAccess, err := s.tokenProvider.CreateToken(user.Username, strings.Join(roles, ","))
		if err != nil {
			return nil, err
		}
		newRefresh, err := s.refreshTokens.RotateRefreshToken(userID, token)
		if err != nil {
			return nil, err
		}
		return map[string]interface{}{
			"jwtToken":              newAccess,
			"accessToken":           newAccess,
			"refreshToken":          newRefresh,
			"tokenType":             "Bearer",
			"expiresIn":             s.tokenProvider.GetAccessTokenExpirationSeconds(),
			"refreshTokenExpiresIn": s.refreshTokens.GetRefreshTokenExpirationSeconds(),
			"username":              user.Username,
			"roles":                 roles,
		}, nil
	}

	// 退化路径：未注入刷新令牌服务时，把传入的 access token 当 refresh token 重签（历史行为）。
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

// Logout 登出：撤销该用户所有 refresh token，并把当前 access token 加入黑名单直至其自然过期。
// 未注入对应服务时静默降级（与历史行为一致）。

func (s *AuthWsService) Logout(username, bearerToken string) error {
	if username == "" {
		return errors.New("authenticated user is required")
	}
	user, err := s.lookupAuthAccount(username)
	if err != nil {
		return errors.New("authenticated user no longer exists")
	}
	if s.refreshTokens != nil {
		_ = s.refreshTokens.RevokeUserTokens(user.UserID)
	}
	if s.blacklist != nil {
		raw := extractBearer(bearerToken)
		if raw != "" {
			if err := s.blacklist.Blacklist(raw, s.tokenProvider.GetExpirationMs(raw)); err != nil {
				// fail-closed：Redis 不可用且 fail-open 关闭时，登出应失败而非假装成功，
				// 否则用户以为 token 已撤销实则未撤销。对齐 Cloud Java 端抛异常的语义。
				return err
			}
		}
	}
	return nil
}

// GetCurrentUserProfile 返回当前登录用户的档案（身份 + 角色 + 绑定的驾驶员）。

func (s *AuthWsService) GetCurrentUserProfile(username string) (map[string]interface{}, error) {
	if strings.TrimSpace(username) == "" {
		return nil, errors.New("user not found")
	}
	user, err := s.lookupAuthAccount(username)
	if err != nil {
		return nil, errors.New("user not found: " + username)
	}
	roles := s.lookupAuthRoles(user)
	displayName := user.Username
	driverID, driverName := s.lookupDriverProfile(user.UserID)
	return map[string]interface{}{
		"authUserId":  user.UserID,
		"username":    user.Username,
		"displayName": displayName,
		"email":       user.Email,
		"phoneNumber": maskPhone(user.ContactNumber),
		"roles":       roles,
		"driverId":    driverID,
		"driverName":  driverName,
	}, nil
}

func (s *AuthWsService) lookupDriverProfile(userID uint64) (any, any) {
	type driverRow struct {
		DriverID int64  `gorm:"column:driver_id"`
		Name     string `gorm:"column:name"`
	}
	var driver driverRow
	if err := s.users.DB().Table("driver_information").
		Where("auth_user_id = ? AND deleted_at IS NULL", userID).
		Take(&driver).Error; err == nil {
		return driver.DriverID, driver.Name
	}
	return nil, nil
}

func extractBearer(header string) string {
	header = strings.TrimSpace(header)
	if !strings.HasPrefix(header, "Bearer ") {
		return ""
	}
	return strings.TrimSpace(strings.TrimPrefix(header, "Bearer "))
}

func maskPhone(phone string) string {
	phone = strings.TrimSpace(phone)
	if phone == "" {
		return phone
	}
	if len(phone) < 7 {
		return string(phone[0]) + "****"
	}
	return phone[:3] + "****" + phone[len(phone)-4:]
}

func (s *AuthWsService) usernameTaken(username string) bool {
	var count int64
	if err := s.users.DB().Table("sys_user").Where("username = ? AND deleted_at IS NULL", username).Count(&count).Error; err == nil && count > 0 {
		return true
	}
	return s.users.IsUsernameExists(username)
}

func (s *AuthWsService) registerSysUser(username, hashed, email, contact string) error {
	row := map[string]interface{}{
		"username":       username,
		"password":       hashed,
		"status":         "Active",
		"email":          email,
		"contact_number": contact,
	}
	if err := s.users.DB().Table("sys_user").Create(row).Error; err != nil {
		return err
	}
	var userID uint64
	if err := s.users.DB().Table("sys_user").Where("username = ? AND deleted_at IS NULL", username).Pluck("user_id", &userID).Error; err != nil || userID == 0 {
		return err
	}
	var roleID uint64
	_ = s.users.DB().Table("sys_role").Where("role_code IN ? AND deleted_at IS NULL", []string{"USER", "DRIVER"}).Order("role_id").Limit(1).Pluck("role_id", &roleID).Error
	if roleID > 0 {
		_ = s.users.DB().Table("sys_user_role").Create(map[string]interface{}{
			"user_id": userID,
			"role_id": roleID,
		}).Error
	}
	return nil
}

func (s *AuthWsService) RegisterUser(req RegisterRequest) (string, error) {
	if strings.TrimSpace(req.Username) == "" || strings.TrimSpace(req.Password) == "" {
		return "", errors.New("username and password are required")
	}
	username := strings.TrimSpace(req.Username)
	if s.usernameTaken(username) {
		return "", errors.New("username already exists")
	}
	hashed, err := shared.HashPassword(req.Password)
	if err != nil {
		return "", err
	}
	if err := s.registerSysUser(username, hashed, req.Email, req.ContactNumber); err == nil {
		return RegisterStatusCreated, nil
	}
	now := time.Now()
	user := &domain.UserManagement{
		Username:      username,
		Password:      hashed,
		ContactNumber: req.ContactNumber,
		Email:         req.Email,
		Status:        "Active",
		CreatedTime:   shared.TimePtr(now),
		ModifiedTime:  shared.TimePtr(now),
	}
	if err := s.users.CreateUser(user); err != nil {
		return "", err
	}
	return RegisterStatusCreated, nil
}

func (s *AuthWsService) GetAllUsers() ([]domain.UserManagement, error) {
	return s.users.GetAllUsers()
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

// AuthService is the canonical auth application service name.
type AuthService = AuthWsService

func NewAuthService(users *admin.UserManagementService, tokenProvider *authcfg.TokenProvider) *AuthWsService {
	return NewAuthWsService(users, tokenProvider)
}
