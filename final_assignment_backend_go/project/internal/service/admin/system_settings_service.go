package admin

import (
	"final_assignment_backend_go/project/internal/service/shared"
	"strconv"
	"strings"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

type SystemSettingsService struct {
	repo *repo.SystemSettingsRepo
}

func NewSystemSettingsService(repo *repo.SystemSettingsRepo) *SystemSettingsService {
	return &SystemSettingsService{repo: repo}
}

func (s *SystemSettingsService) CreateSettings(settings *domain.SystemSettings) error {
	return s.repo.Create(settings)
}

func (s *SystemSettingsService) DB() *gorm.DB { return s.repo.DB() }

func (s *SystemSettingsService) GetSystemSettings() (*domain.SystemSettings, error) {
	var rows []domain.SysSetting
	if err := s.DB().Find(&rows).Error; err != nil {
		if shared.IsMissingTable(err) {
			return &domain.SystemSettings{SystemName: "交通违法处理管理系统", SystemVersion: "2.0.0", DateFormat: "YYYY-MM-DD", PageSize: 20}, nil
		}
		return nil, err
	}
	values := map[string]string{}
	for _, row := range rows {
		values[row.SettingKey] = row.SettingValue
	}
	settings := &domain.SystemSettings{
		SystemName:        shared.FirstNonEmpty(values["system.name"], "交通违法处理管理系统"),
		SystemVersion:     shared.FirstNonEmpty(values["system.version"], "2.0.0"),
		SystemDescription: values["system.description"],
		CopyrightInfo:     values["system.copyright"],
		StoragePath:       values["system.storage_path"],
		LoginTimeout:      shared.AtoiDefault(values["system.login_timeout"], 30),
		SessionTimeout:    shared.AtoiDefault(values["system.session_timeout"], 120),
		DateFormat:        shared.FirstNonEmpty(values["system.date_format"], "YYYY-MM-DD"),
		PageSize:          shared.AtoiDefault(values["system.page_size"], 20),
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
	if err := shared.CheckIdempotency(key, "system-settings:update"); err != nil {
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

func (s *SystemSettingsService) GetSystemName() string { return s.current().SystemName }

func (s *SystemSettingsService) GetSystemVersion() string { return s.current().SystemVersion }

func (s *SystemSettingsService) GetSystemDescription() string { return s.current().SystemDescription }

func (s *SystemSettingsService) GetCopyrightInfo() string { return s.current().CopyrightInfo }

func (s *SystemSettingsService) GetStoragePath() string { return s.current().StoragePath }

func (s *SystemSettingsService) GetLoginTimeout() int { return s.current().LoginTimeout }

func (s *SystemSettingsService) GetSessionTimeout() int { return s.current().SessionTimeout }

func (s *SystemSettingsService) GetDateFormat() string { return s.current().DateFormat }

func (s *SystemSettingsService) GetPageSize() int { return s.current().PageSize }

func (s *SystemSettingsService) GetSmtpServer() string { return s.current().SMTPServer }

func (s *SystemSettingsService) GetEmailAccount() string { return s.current().EmailAccount }

func (s *SystemSettingsService) GetEmailPassword() string { return s.current().EmailPassword }
