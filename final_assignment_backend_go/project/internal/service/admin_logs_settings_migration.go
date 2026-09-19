package service

import (
	"strconv"
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
	return distinctStrings(s.DB(), "audit_login_log", "username", prefix, 10)
}
func (s *LoginLogService) GetLoginResultsByPrefixGlobally(prefix string) []string {
	return distinctStrings(s.DB(), "audit_login_log", "login_result", prefix, 10)
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
	return distinctStrings(s.DB(), "audit_operation_log", "CAST(user_id AS CHAR)", prefix, 10), nil
}
func (s *OperationLogService) GetOperationResultsByPrefixGlobally(prefix string) ([]string, error) {
	return distinctStrings(s.DB(), "audit_operation_log", "operation_result", prefix, 10), nil
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
	err := s.DB().Where("operation_type = ?", logType).Find(&logs).Error
	return logs, err
}
func (s *SystemLogsService) GetSystemLogsByTimeRange(start time.Time, end time.Time) ([]domain.SystemLogs, error) {
	var logs []domain.SystemLogs
	err := s.DB().Where("operation_time BETWEEN ? AND ?", start, end).Find(&logs).Error
	return logs, err
}
func (s *SystemLogsService) GetSystemLogsByOperationUser(user string) ([]domain.SystemLogs, error) {
	var logs []domain.SystemLogs
	err := s.DB().Where("username = ?", user).Find(&logs).Error
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
	return distinctStrings(s.DB(), "audit_operation_log", "operation_type", prefix, 10), nil
}
func (s *SystemLogsService) GetOperationUsersByPrefixGlobally(prefix string) ([]string, error) {
	return distinctStrings(s.DB(), "audit_operation_log", "username", prefix, 10), nil
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
	items, err := s.repo.FindAll()
	if isMissingTable(err) {
		return []domain.ProgressItem{}, nil
	}
	return items, err
}
func (s *ProgressItemService) GetProgressByUsername(username string) ([]domain.ProgressItem, error) {
	var items []domain.ProgressItem
	err := s.DB().Where("username = ?", username).Find(&items).Error
	if isMissingTable(err) {
		return []domain.ProgressItem{}, nil
	}
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
	var rows []domain.SysSetting
	if err := s.DB().Find(&rows).Error; err != nil {
		if isMissingTable(err) {
			return &domain.SystemSettings{SystemName: "交通违法处理管理系统", SystemVersion: "2.0.0", DateFormat: "YYYY-MM-DD", PageSize: 20}, nil
		}
		return nil, err
	}
	values := map[string]string{}
	for _, row := range rows {
		values[row.SettingKey] = row.SettingValue
	}
	settings := &domain.SystemSettings{
		SystemName:        firstNonEmpty(values["system.name"], "交通违法处理管理系统"),
		SystemVersion:     firstNonEmpty(values["system.version"], "2.0.0"),
		SystemDescription: values["system.description"],
		CopyrightInfo:     values["system.copyright"],
		StoragePath:       values["system.storage_path"],
		LoginTimeout:      atoiDefault(values["system.login_timeout"], 30),
		SessionTimeout:    atoiDefault(values["system.session_timeout"], 120),
		DateFormat:        firstNonEmpty(values["system.date_format"], "YYYY-MM-DD"),
		PageSize:          atoiDefault(values["system.page_size"], 20),
		SMTPServer:        values["system.smtp_server"],
		EmailAccount:      values["system.email_account"],
		EmailPassword:     values["system.email_password"],
	}
	if len(rows) > 0 {
		settings.SettingID = rows[0].SettingID
	}
	return settings, nil
}
func (s *SystemSettingsService) CheckAndInsertIdempotency(key string, settings *domain.SystemSettings) error {
	if err := checkIdempotency(key, "system-settings:update"); err != nil {
		return err
	}
	pairs := map[string]string{
		"system.name":            settings.SystemName,
		"system.version":         settings.SystemVersion,
		"system.description":     settings.SystemDescription,
		"system.copyright":       settings.CopyrightInfo,
		"system.storage_path":    settings.StoragePath,
		"system.login_timeout":   strconv.Itoa(settings.LoginTimeout),
		"system.session_timeout": strconv.Itoa(settings.SessionTimeout),
		"system.date_format":     settings.DateFormat,
		"system.page_size":       strconv.Itoa(settings.PageSize),
		"system.smtp_server":     settings.SMTPServer,
		"system.email_account":   settings.EmailAccount,
		"system.email_password":  settings.EmailPassword,
	}
	for settingKey, value := range pairs {
		if strings.TrimSpace(settingKey) == "" {
			continue
		}
		_ = s.DB().Model(&domain.SysSetting{}).Where("setting_key = ?", settingKey).Update("setting_value", value).Error
	}
	return nil
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
