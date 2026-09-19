package audit

import (
	"final_assignment_backend_go/project/internal/service/shared"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

type OperationLogService struct {
	repo *repo.OperationLogRepo
}

func NewOperationLogService(repo *repo.OperationLogRepo) *OperationLogService {
	return &OperationLogService{repo: repo}
}

func (s *OperationLogService) CreateLog(log *domain.OperationLog) error {
	return s.repo.Create(log)
}

func (s *OperationLogService) DB() *gorm.DB { return s.repo.DB() }

func (s *OperationLogService) CheckAndInsertIdempotency(key string, logEntry *domain.OperationLog, operation string) error {
	if err := shared.CheckIdempotency(key, "operation-log:"+operation); err != nil {
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
	return shared.DistinctStrings(s.DB(), "audit_operation_log", "CAST(user_id AS CHAR)", prefix, 10), nil
}

func (s *OperationLogService) GetOperationResultsByPrefixGlobally(prefix string) ([]string, error) {
	return shared.DistinctStrings(s.DB(), "audit_operation_log", "operation_result", prefix, 10), nil
}
