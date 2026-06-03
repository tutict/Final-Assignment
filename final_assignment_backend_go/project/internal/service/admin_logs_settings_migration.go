package service

import (
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"

	"gorm.io/gorm"
)

func (s *LoginLogService) DB() *gorm.DB { return s.repo.DB() }

func (s *LoginLogService) CheckAndInsertIdempotency(key string, logEntry *domain.LoginLog, operation string) error {
	if err := checkIdempotency(key, "login-log:"+operation); err != nil {
		return err
	}
	if strings.EqualFold(operation, "create") {
		if logEntry.LoginTime.IsZero() {
			logEntry.LoginTime = time.Now()
		}
		return s.DB().Create(logEntry).Error
	}
	return s.DB().Save(logEntry).Error
}

func (s *LoginLogService) GetLoginLogByID(id string) (*domain.LoginLog, error) {
	parsed, err := parseID(id)
	if err != nil {
		return nil, err
	}
	var logEntry domain.LoginLog
	err = s.DB().Where("log_id = ?", parsed).First(&logEntry).Error
	return &logEntry, err
}
func (s *LoginLogService) GetAllLoginLogs() ([]domain.LoginLog, error) { return s.repo.FindAll() }
func (s *LoginLogService) DeleteLoginLog(id string) error {
	parsed, err := parseID(id)
	if err != nil {
		return err
	}
	return s.DB().Where("log_id = ?", parsed).Delete(&domain.LoginLog{}).Error
}
func (s *LoginLogService) GetLoginLogsByTimeRange(start time.Time, end time.Time) ([]domain.LoginLog, error) {
	var logs []domain.LoginLog
	err := s.DB().Where("login_time BETWEEN ? AND ?", start, end).Find(&logs).Error
	return logs, err
}
func (s *LoginLogService) GetLoginLogsByUsername(username string) ([]domain.LoginLog, error) {
	var logs []domain.LoginLog
	err := s.DB().Where("username = ?", username).Find(&logs).Error
	return logs, err
}
func (s *LoginLogService) GetLoginLogsByLoginResult(result string) ([]domain.LoginLog, error) {
	var logs []domain.LoginLog
	err := s.DB().Where("login_result = ?", result).Find(&logs).Error
	return logs, err
}
func (s *LoginLogService) GetUsernamesByPrefixGlobally(prefix string) []string {
	return distinctStrings(s.DB(), "login_log", "username", prefix, 10)
}
func (s *LoginLogService) GetLoginResultsByPrefixGlobally(prefix string) []string {
	return distinctStrings(s.DB(), "login_log", "login_result", prefix, 10)
}

func (s *OperationLogService) DB() *gorm.DB { return s.repo.DB() }

func (s *OperationLogService) CheckAndInsertIdempotency(key string, logEntry *domain.OperationLog, operation string) error {
	if err := checkIdempotency(key, "operation-log:"+operation); err != nil {
		return err
	}
	if strings.EqualFold(operation, "create") {
		if logEntry.OperationTime.IsZero() {
			logEntry.OperationTime = time.Now()
		}
		return s.DB().Create(logEntry).Error
	}
	return s.DB().Save(logEntry).Error
}

func (s *OperationLogService) GetOperationLog(id int) (*domain.OperationLog, error) {
	var logEntry domain.OperationLog
	err := s.DB().Where("log_id = ?", id).First(&logEntry).Error
	return &logEntry, err
}
func (s *OperationLogService) GetAllOperationLogs() ([]domain.OperationLog, error) {
	return s.repo.FindAll()
}
func (s *OperationLogService) DeleteOperationLog(id int) error {
	return s.DB().Where("log_id = ?", id).Delete(&domain.OperationLog{}).Error
}
func (s *OperationLogService) GetOperationLogsByTimeRange(start time.Time, end time.Time) ([]domain.OperationLog, error) {
	var logs []domain.OperationLog
	err := s.DB().Where("operation_time BETWEEN ? AND ?", start, end).Find(&logs).Error
	return logs, err
}
func (s *OperationLogService) GetOperationLogsByUserId(userID string) ([]domain.OperationLog, error) {
	var logs []domain.OperationLog
	err := s.DB().Where("user_id = ?", userID).Find(&logs).Error
	return logs, err
}
func (s *OperationLogService) GetOperationLogsByResult(result string) ([]domain.OperationLog, error) {
	var logs []domain.OperationLog
	err := s.DB().Where("operation_result = ?", result).Find(&logs).Error
	return logs, err
}
func (s *OperationLogService) GetUserIdsByPrefixGlobally(prefix string) ([]string, error) {
	return distinctStrings(s.DB(), "operation_log", "CAST(user_id AS CHAR)", prefix, 10), nil
}
func (s *OperationLogService) GetOperationResultsByPrefixGlobally(prefix string) ([]string, error) {
	return distinctStrings(s.DB(), "operation_log", "operation_result", prefix, 10), nil
}

func (s *SystemLogsService) DB() *gorm.DB { return s.repo.DB() }

func (s *SystemLogsService) CheckAndInsertIdempotency(key string, logEntry *domain.SystemLogs, operation string) error {
	if err := checkIdempotency(key, "system-log:"+operation); err != nil {
		return err
	}
	if strings.EqualFold(operation, "create") {
		if logEntry.OperationTime.IsZero() {
			logEntry.OperationTime = time.Now()
		}
		return s.DB().Create(logEntry).Error
	}
	return s.DB().Save(logEntry).Error
}

func (s *SystemLogsService) GetSystemLogByID(id string) (*domain.SystemLogs, error) {
	parsed, err := parseID(id)
	if err != nil {
		return nil, err
	}
	var logEntry domain.SystemLogs
	err = s.DB().Where("log_id = ?", parsed).First(&logEntry).Error
	return &logEntry, err
}
func (s *SystemLogsService) GetAllSystemLogs() ([]domain.SystemLogs, error) { return s.repo.FindAll() }
func (s *SystemLogsService) GetSystemLogsByType(logType string) ([]domain.SystemLogs, error) {
	var logs []domain.SystemLogs
	err := s.DB().Where("log_type = ?", logType).Find(&logs).Error
	return logs, err
}
func (s *SystemLogsService) GetSystemLogsByTimeRange(start time.Time, end time.Time) ([]domain.SystemLogs, error) {
	var logs []domain.SystemLogs
	err := s.DB().Where("operation_time BETWEEN ? AND ?", start, end).Find(&logs).Error
	return logs, err
}
func (s *SystemLogsService) GetSystemLogsByOperationUser(user string) ([]domain.SystemLogs, error) {
	var logs []domain.SystemLogs
	err := s.DB().Where("operation_user = ?", user).Find(&logs).Error
	return logs, err
}
func (s *SystemLogsService) DeleteSystemLog(id string) error {
	parsed, err := parseID(id)
	if err != nil {
		return err
	}
	return s.DB().Where("log_id = ?", parsed).Delete(&domain.SystemLogs{}).Error
}
func (s *SystemLogsService) GetLogTypesByPrefixGlobally(prefix string) ([]string, error) {
	return distinctStrings(s.DB(), "system_logs", "log_type", prefix, 10), nil
}
func (s *SystemLogsService) GetOperationUsersByPrefixGlobally(prefix string) ([]string, error) {
	return distinctStrings(s.DB(), "system_logs", "operation_user", prefix, 10), nil
}

func (s *PermissionManagementService) DB() *gorm.DB { return s.repo.DB() }

func (s *PermissionManagementService) CheckAndInsertIdempotency(key string, permission *domain.PermissionManagement, operation string) error {
	if err := checkIdempotency(key, "permission:"+operation); err != nil {
		return err
	}
	now := time.Now()
	if strings.EqualFold(operation, "create") {
		permission.CreatedTime = now
		permission.ModifiedTime = now
		return s.DB().Create(permission).Error
	}
	permission.ModifiedTime = now
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

func (s *RoleManagementService) DB() *gorm.DB { return s.repo.DB() }

func (s *RoleManagementService) CheckAndInsertIdempotency(key string, role *domain.RoleManagement, operation string) error {
	if err := checkIdempotency(key, "role:"+operation); err != nil {
		return err
	}
	now := time.Now()
	if strings.EqualFold(operation, "create") {
		role.CreatedTime = now
		role.ModifiedTime = now
		return s.DB().Create(role).Error
	}
	role.ModifiedTime = now
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

func (s *ProgressItemService) DB() *gorm.DB { return s.repo.DB() }

func (s *ProgressItemService) CreateProgress(progress *domain.ProgressItem) (*domain.ProgressItem, error) {
	if progress.SubmitTime.IsZero() {
		progress.SubmitTime = time.Now()
	}
	if progress.Status == "" {
		progress.Status = "PENDING"
	}
	return progress, s.DB().Create(progress).Error
}
func (s *ProgressItemService) GetAllProgress() ([]domain.ProgressItem, error) {
	return s.repo.FindAll()
}
func (s *ProgressItemService) GetProgressByUsername(username string) ([]domain.ProgressItem, error) {
	var items []domain.ProgressItem
	err := s.DB().Where("username = ?", username).Find(&items).Error
	return items, err
}
func (s *ProgressItemService) UpdateProgressStatus(id int, status string) (*domain.ProgressItem, error) {
	var item domain.ProgressItem
	if err := s.DB().Where("id = ?", id).First(&item).Error; err != nil {
		return nil, err
	}
	item.Status = status
	return &item, s.DB().Save(&item).Error
}
func (s *ProgressItemService) DeleteProgress(id int) error {
	return s.DB().Where("id = ?", id).Delete(&domain.ProgressItem{}).Error
}
func (s *ProgressItemService) GetProgressByStatus(status string) ([]domain.ProgressItem, error) {
	var items []domain.ProgressItem
	err := s.DB().Where("status = ?", status).Find(&items).Error
	return items, err
}
func (s *ProgressItemService) GetProgressByTimeRange(start time.Time, end time.Time) ([]domain.ProgressItem, error) {
	var items []domain.ProgressItem
	err := s.DB().Where("submit_time BETWEEN ? AND ?", start, end).Find(&items).Error
	return items, err
}

func (s *SystemSettingsService) DB() *gorm.DB { return s.repo.DB() }

func (s *SystemSettingsService) GetSystemSettings() (*domain.SystemSettings, error) {
	var settings domain.SystemSettings
	err := s.DB().First(&settings).Error
	return &settings, err
}
func (s *SystemSettingsService) CheckAndInsertIdempotency(key string, settings *domain.SystemSettings) error {
	if err := checkIdempotency(key, "system-settings:update"); err != nil {
		return err
	}
	return s.DB().Save(settings).Error
}
func (s *SystemSettingsService) current() *domain.SystemSettings {
	settings, err := s.GetSystemSettings()
	if err != nil {
		return &domain.SystemSettings{}
	}
	return settings
}
func (s *SystemSettingsService) GetSystemName() string        { return s.current().SystemName }
func (s *SystemSettingsService) GetSystemVersion() string     { return s.current().SystemVersion }
func (s *SystemSettingsService) GetSystemDescription() string { return s.current().SystemDescription }
func (s *SystemSettingsService) GetCopyrightInfo() string     { return s.current().CopyrightInfo }
func (s *SystemSettingsService) GetStoragePath() string       { return s.current().StoragePath }
func (s *SystemSettingsService) GetLoginTimeout() int         { return s.current().LoginTimeout }
func (s *SystemSettingsService) GetSessionTimeout() int       { return s.current().SessionTimeout }
func (s *SystemSettingsService) GetDateFormat() string        { return s.current().DateFormat }
func (s *SystemSettingsService) GetPageSize() int             { return s.current().PageSize }
func (s *SystemSettingsService) GetSmtpServer() string        { return s.current().SMTPServer }
func (s *SystemSettingsService) GetEmailAccount() string      { return s.current().EmailAccount }
func (s *SystemSettingsService) GetEmailPassword() string     { return s.current().EmailPassword }
