package system

import (
	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service/shared"

	"gorm.io/gorm"
)

type SysRolePermissionQuery struct {
	db *gorm.DB
}

func NewSysRolePermissionQuery(db *gorm.DB) *SysRolePermissionQuery {
	return &SysRolePermissionQuery{db: db}
}

func (q *SysRolePermissionQuery) ListRolePermissions() ([]domain.SysRolePermission, error) {
	if q == nil || q.db == nil {
		return []domain.SysRolePermission{}, nil
	}
	var rows []domain.SysRolePermission
	err := q.db.Order("id desc").Find(&rows).Error
	if shared.IsMissingTable(err) {
		return []domain.SysRolePermission{}, nil
	}
	return rows, err
}
