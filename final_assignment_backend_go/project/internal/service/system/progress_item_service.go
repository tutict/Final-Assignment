package system

import (
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"
)

// ProgressItemService 处理 /api/progress，持久化落在共享的 sys_request_history 表。
type ProgressItemService struct {
	repo *repo.ProgressItemRepo
}

func NewProgressItemService(repo *repo.ProgressItemRepo) *ProgressItemService {
	return &ProgressItemService{repo: repo}
}

func (s *ProgressItemService) CreateItem(item *domain.ProgressItem) error {
	return s.repo.Create(item)
}

func (s *ProgressItemService) CreateProgress(progress *domain.ProgressItem, idempotencyKey string) (*domain.ProgressItem, error) {
	if progress.SubmitTime.IsZero() {
		progress.SubmitTime = time.Now()
	}
	if progress.Status == "" {
		progress.Status = "PENDING"
	}
	if err := s.repo.CreateWithKey(progress, idempotencyKey); err != nil {
		return nil, err
	}
	return progress, nil
}

func (s *ProgressItemService) FindProgressByIdempotencyKey(key string) (*domain.ProgressItem, error) {
	return s.repo.FindByIdempotencyKey(key)
}

func (s *ProgressItemService) GetAllProgress() ([]domain.ProgressItem, error) {
	return s.repo.FindAll()
}

func (s *ProgressItemService) GetProgressByUsername(username string) ([]domain.ProgressItem, error) {
	return s.repo.FindByUsername(username)
}

func (s *ProgressItemService) UpdateProgress(item *domain.ProgressItem) (*domain.ProgressItem, error) {
	return s.repo.Update(item)
}

func (s *ProgressItemService) UpdateProgressStatus(id int, status string) (*domain.ProgressItem, error) {
	return s.repo.Update(&domain.ProgressItem{ID: id, Status: status})
}

func (s *ProgressItemService) DeleteProgress(id int) error {
	return s.repo.Delete(id)
}

func (s *ProgressItemService) GetProgressByStatus(status string) ([]domain.ProgressItem, error) {
	return s.repo.FindByStatus(status)
}

func (s *ProgressItemService) GetProgressByTimeRange(start time.Time, end time.Time) ([]domain.ProgressItem, error) {
	return s.repo.FindByTimeRange(start, end)
}

type ProgressService = ProgressItemService
