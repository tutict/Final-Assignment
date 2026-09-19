package system

import (
	"final_assignment_backend_go/project/internal/service/shared"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

type ProgressItemService struct {
	repo *repo.ProgressItemRepo
}

func NewProgressItemService(repo *repo.ProgressItemRepo) *ProgressItemService {
	return &ProgressItemService{repo: repo}
}

func (s *ProgressItemService) CreateItem(item *domain.ProgressItem) error {
	return s.repo.Create(item)
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
	if shared.IsMissingTable(err) {
		return []domain.ProgressItem{}, nil
	}
	return items, err
}

func (s *ProgressItemService) GetProgressByUsername(username string) ([]domain.ProgressItem, error) {
	var items []domain.ProgressItem
	err := s.DB().Where("username = ?", username).Find(&items).Error
	if shared.IsMissingTable(err) {
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

type ProgressService = ProgressItemService
