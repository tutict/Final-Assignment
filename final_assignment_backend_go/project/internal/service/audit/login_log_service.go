package audit

import (
	"final_assignment_backend_go/project/internal/service/shared"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

type LoginLogService struct {
	repo *repo.LoginLogRepo
}

func NewLoginLogService(repo *repo.LoginLogRepo) *LoginLogService {
	return &LoginLogService{repo: repo}
}

func (s *LoginLogService) CreateLog(log *domain.LoginLog) error {
	return s.repo.Create(log)
}

func (s *LoginLogService) DB() *gorm.DB { return s.repo.DB() }

func (s *LoginLogService) CheckAndInsertIdempotency(key string, logEntry *domain.LoginLog, operation string) error {
	if err := shared.CheckIdempotency(key, "login-log:"+operation); err != nil {
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
	parsed, err := shared.ParseID(id)
	if err != nil {
		return nil, err
	}
	var logEntry domain.LoginLog
	err = s.DB().Where("log_id = ?", parsed).First(&logEntry).Error
	return &logEntry, err
}

func (s *LoginLogService) GetAllLoginLogs() ([]domain.LoginLog, error) { return s.repo.FindAll() }

func (s *LoginLogService) DeleteLoginLog(id string) error {
	parsed, err := shared.ParseID(id)
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
	return shared.DistinctStrings(s.DB(), "audit_login_log", "username", prefix, 10)
}

func (s *LoginLogService) GetLoginResultsByPrefixGlobally(prefix string) []string {
	return shared.DistinctStrings(s.DB(), "audit_login_log", "login_result", prefix, 10)
}
