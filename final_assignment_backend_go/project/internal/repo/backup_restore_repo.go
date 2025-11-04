package repo

import (
	"final_assignment_backend_go/project/internal/domain"

	"gorm.io/gorm"
)

// BackupRestoreRepo 提供 BackupRestore 的数据库操作
type BackupRestoreRepo struct {
	db *gorm.DB
}

// NewBackupRestoreRepo 创建新的仓库实例
func NewBackupRestoreRepo(db *gorm.DB) *BackupRestoreRepo {
	return &BackupRestoreRepo{db: db}
}

// Create 创建新的 BackupRestore 记录
func (r *BackupRestoreRepo) Create(backup *domain.BackupRestore) error {
	return r.db.Create(backup).Error
}

// FindAll 获取所有 BackupRestore 记录
func (r *BackupRestoreRepo) FindAll() ([]domain.BackupRestore, error) {
	var backups []domain.BackupRestore
	err := r.db.Find(&backups).Error
	return backups, err
}
