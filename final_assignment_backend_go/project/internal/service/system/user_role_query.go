package system

import (
	"errors"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service/shared"

	"gorm.io/gorm"
)

type SysUserRoleQuery struct {
	db *gorm.DB
}

func NewSysUserRoleQuery(db *gorm.DB) *SysUserRoleQuery {
	return &SysUserRoleQuery{db: db}
}

func (q *SysUserRoleQuery) ListUserRoles() ([]domain.SysUserRole, error) {
	if q == nil || q.db == nil {
		return []domain.SysUserRole{}, nil
	}
	var rows []domain.SysUserRole
	err := q.db.Order("id desc").Find(&rows).Error
	if shared.IsMissingTable(err) {
		return []domain.SysUserRole{}, nil
	}
	return rows, err
}

func (q *SysUserRoleQuery) CreateUserRole(row *domain.SysUserRole) error {
	if q == nil || q.db == nil {
		return errors.New("user role store is not configured")
	}
	return q.db.Create(row).Error
}

func (q *SysUserRoleQuery) UpdateUserRole(row *domain.SysUserRole) error {
	if q == nil || q.db == nil {
		return errors.New("user role store is not configured")
	}
	result := q.db.Model(&domain.SysUserRole{}).Where("id = ?", row.ID).Updates(map[string]any{
		"user_id": row.UserID,
		"role_id": row.RoleID,
	})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (q *SysUserRoleQuery) DeleteUserRole(id int64) error {
	if q == nil || q.db == nil {
		return errors.New("user role store is not configured")
	}
	result := q.db.Delete(&domain.SysUserRole{}, id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
