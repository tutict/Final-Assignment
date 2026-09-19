package audit

import (
	"final_assignment_backend_go/project/internal/service/shared"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

type SystemLogsService struct {
	repo *repo.SystemLogsRepo
}

func NewSystemLogsService(repo *repo.SystemLogsRepo) *SystemLogsService {
	return &SystemLogsService{repo: repo}
}

func (s *SystemLogsService) CreateLog(log *domain.SystemLogs) error {
	return s.repo.Create(log)
}

func (s *SystemLogsService) DB() *gorm.DB { return s.repo.DB() }

func (s *SystemLogsService) CheckAndInsertIdempotency(key string, logEntry *domain.SystemLogs, operation string) error {
	if err := shared.CheckIdempotency(key, "system-log:"+operation); err != nil {
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
	parsed, err := shared.ParseID(id)
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
	parsed, err := shared.ParseID(id)
	if err != nil {
		return err
	}
	return s.DB().Where("log_id = ?", parsed).Delete(&domain.SystemLogs{}).Error
}

func (s *SystemLogsService) GetLogTypesByPrefixGlobally(prefix string) ([]string, error) {
	return shared.DistinctStrings(s.DB(), "audit_operation_log", "operation_type", prefix, 10), nil
}

func (s *SystemLogsService) GetOperationUsersByPrefixGlobally(prefix string) ([]string, error) {
	return shared.DistinctStrings(s.DB(), "audit_operation_log", "username", prefix, 10), nil
}
