package repo

import (
	"final_assignment_backend_go/project/internal/domain"

	"gorm.io/gorm"
)

// PaymentRecordRepo 提供 PaymentRecord 的数据库操作
type PaymentRecordRepo struct {
	db *gorm.DB
}

// NewPaymentRecordRepo 创建新的仓库实例
func NewPaymentRecordRepo(db *gorm.DB) *PaymentRecordRepo {
	return &PaymentRecordRepo{db: db}
}

// Create 创建新的 PaymentRecord 记录
func (r *PaymentRecordRepo) Create(payment *domain.PaymentRecord) error {
	return r.db.Create(payment).Error
}

// FindAll 获取所有 PaymentRecord 记录
func (r *PaymentRecordRepo) FindAll() ([]domain.PaymentRecord, error) {
	var payments []domain.PaymentRecord
	err := r.db.Find(&payments).Error
	return payments, err
}
