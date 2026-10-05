package system

import (
	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service/shared"

	"gorm.io/gorm"
)

type SysRequestHistoryQuery struct {
	db *gorm.DB
}

func NewSysRequestHistoryQuery(db *gorm.DB) *SysRequestHistoryQuery {
	return &SysRequestHistoryQuery{db: db}
}

func (q *SysRequestHistoryQuery) ListSysRequestHistory() ([]domain.SysRequestHistory, error) {
	if q == nil || q.db == nil {
		return []domain.SysRequestHistory{}, nil
	}
	var rows []domain.SysRequestHistory
	err := q.db.Order("id desc").Find(&rows).Error
	if shared.IsMissingTable(err) {
		return []domain.SysRequestHistory{}, nil
	}
	return rows, err
}
