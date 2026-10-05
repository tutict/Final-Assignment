package system

import (
	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service/shared"

	"gorm.io/gorm"
)

type SysDictQuery struct {
	db *gorm.DB
}

func NewSysDictQuery(db *gorm.DB) *SysDictQuery {
	return &SysDictQuery{db: db}
}

func (q *SysDictQuery) ListSysDicts() ([]domain.SysDict, error) {
	if q == nil || q.db == nil {
		return []domain.SysDict{}, nil
	}
	var rows []domain.SysDict
	err := q.db.Order("sort_order asc, dict_id asc").Find(&rows).Error
	if shared.IsMissingTable(err) {
		return []domain.SysDict{}, nil
	}
	return rows, err
}
