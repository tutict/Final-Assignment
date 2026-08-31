package service

import (
	"errors"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

var (
	// ErrPaymentDuplicate 对齐 Spring 的 PaymentDuplicateRequestException（HTTP 208）。
	ErrPaymentDuplicate = errors.New("duplicate payment request detected")
	// ErrPaymentOptimisticLock 对齐 Spring 的 PaymentOptimisticLockException（HTTP 409）。
	ErrPaymentOptimisticLock = errors.New("payment record was updated concurrently")
	// ErrPaymentNotFound 表示支付记录不存在（HTTP 404）。
	ErrPaymentNotFound = errors.New("payment record not found")
)

// PaymentRecordService 提供支付记录的业务逻辑，对齐 Spring 的
// com.tutict.finalassignmentbackend.service.payment.PaymentRecordService。
type PaymentRecordService struct {
	repo *repo.PaymentRecordRepo
}

func NewPaymentRecordService(paymentRepo *repo.PaymentRecordRepo) *PaymentRecordService {
	return &PaymentRecordService{repo: paymentRepo}
}

func (s *PaymentRecordService) DB() *gorm.DB { return s.repo.DB() }

// CheckAndInsertIdempotency 幂等检查 + 落库，沿用 Go 后端统一的幂等账本。
func (s *PaymentRecordService) CheckAndInsertIdempotency(key string, payment *domain.PaymentRecord, operation string) error {
	if err := checkIdempotency(key, "payment:"+operation); err != nil {
		return ErrPaymentDuplicate
	}
	if strings.EqualFold(operation, "create") {
		return s.CreatePayment(payment)
	}
	return s.UpdatePayment(payment)
}

// CreatePayment 创建支付记录，缺省补齐支付状态与时间戳。
func (s *PaymentRecordService) CreatePayment(payment *domain.PaymentRecord) error {
	if payment == nil {
		return errors.New("payment record must not be null")
	}
	if payment.FineID <= 0 {
		return errors.New("fineId must be greater than zero")
	}
	if strings.TrimSpace(payment.PaymentMethod) == "" {
		return errors.New("paymentMethod must not be blank")
	}
	if strings.TrimSpace(payment.PayerName) == "" {
		return errors.New("payerName must not be blank")
	}
	now := time.Now()
	if payment.PaymentTime == nil {
		payment.PaymentTime = &now
	}
	if strings.TrimSpace(payment.PaymentStatus) == "" {
		payment.PaymentStatus = "Pending"
	}
	return s.DB().Create(payment).Error
}

// UpdatePayment 按主键乐观锁更新（对齐 MyBatis-Plus @Version 行为）。
func (s *PaymentRecordService) UpdatePayment(payment *domain.PaymentRecord) error {
	if payment == nil || payment.PaymentID <= 0 {
		return errors.New("payment ID must be greater than zero")
	}
	query := s.DB().Model(&domain.PaymentRecord{}).
		Where("payment_id = ?", payment.PaymentID)
	if payment.Version > 0 {
		query = query.Where("version = ?", payment.Version)
	}
	result := query.Updates(map[string]any{
		"fine_id":         payment.FineID,
		"driver_id":       payment.DriverID,
		"payment_number":  payment.PaymentNumber,
		"payment_amount":  payment.PaymentAmount,
		"payment_method":  payment.PaymentMethod,
		"payment_time":    payment.PaymentTime,
		"payment_channel": payment.PaymentChannel,
		"payer_name":      payment.PayerName,
		"payer_id_card":   payment.PayerIDCard,
		"payer_contact":   payment.PayerContact,
		"bank_name":       payment.BankName,
		"bank_account":    payment.BankAccount,
		"transaction_id":  payment.TransactionID,
		"receipt_number":  payment.ReceiptNumber,
		"receipt_url":     payment.ReceiptURL,
		"payment_status":  payment.PaymentStatus,
		"refund_amount":   payment.RefundAmount,
		"refund_time":     payment.RefundTime,
		"updated_at":      time.Now(),
		"remarks":         payment.Remarks,
		"version":         gorm.Expr("version + 1"),
	})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		if _, err := s.FindByID(payment.PaymentID); err != nil {
			return ErrPaymentNotFound
		}
		return ErrPaymentOptimisticLock
	}
	return nil
}

// UpdatePaymentStatus 按状态机目标状态更新支付状态，带乐观锁守卫。
func (s *PaymentRecordService) UpdatePaymentStatus(paymentID int64, status string, idempotencyKey string) (*domain.PaymentRecord, error) {
	if err := checkIdempotency(idempotencyKey, "payment:status"); err != nil {
		return nil, ErrPaymentDuplicate
	}
	if err := s.UpdatePaymentStatusFields(paymentID, status); err != nil {
		return nil, err
	}
	return s.FindByID(paymentID)
}

// UpdatePaymentStatusFields 仅执行状态字段的乐观锁更新（工作流复用）。
func (s *PaymentRecordService) UpdatePaymentStatusFields(paymentID int64, status string) error {
	existing, err := s.FindByID(paymentID)
	if err != nil {
		return ErrPaymentNotFound
	}
	if status != "" && existing.PaymentStatus == status {
		return ErrPaymentOptimisticLock
	}
	now := time.Now()
	result := s.DB().Model(&domain.PaymentRecord{}).
		Where("payment_id = ? AND version = ?", paymentID, existing.Version).
		Updates(map[string]any{
			"payment_status": status,
			"updated_at":     now,
			"version":        existing.Version + 1,
		})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return ErrPaymentOptimisticLock
	}
	return nil
}

// DeletePayment 删除支付记录（软删除）。
func (s *PaymentRecordService) DeletePayment(paymentID int64) error {
	result := s.DB().Where("payment_id = ?", paymentID).Delete(&domain.PaymentRecord{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return ErrPaymentNotFound
	}
	return nil
}

// FindByID 按主键查询支付记录。
func (s *PaymentRecordService) FindByID(paymentID int64) (*domain.PaymentRecord, error) {
	var payment domain.PaymentRecord
	err := s.DB().Where("payment_id = ?", paymentID).First(&payment).Error
	if err != nil {
		return nil, err
	}
	return &payment, nil
}

// GetAllPayments 查询全部支付记录。
func (s *PaymentRecordService) GetAllPayments() ([]domain.PaymentRecord, error) {
	return s.repo.FindAll()
}

// FindByFineID 按罚款记录分页查询支付记录。
func (s *PaymentRecordService) FindByFineID(fineID int64, page int, size int) ([]domain.PaymentRecord, error) {
	offset, limit := pageBounds(page, size)
	var payments []domain.PaymentRecord
	err := s.DB().Where("fine_id = ?", fineID).
		Order("payment_id DESC").Offset(offset).Limit(limit).Find(&payments).Error
	return payments, err
}

// FindByDriverID 按驾驶员分页查询支付记录。
func (s *PaymentRecordService) FindByDriverID(driverID int64, page int, size int) ([]domain.PaymentRecord, error) {
	offset, limit := pageBounds(page, size)
	var payments []domain.PaymentRecord
	err := s.DB().Where("driver_id = ?", driverID).
		Order("payment_id DESC").Offset(offset).Limit(limit).Find(&payments).Error
	return payments, err
}

// SearchByPayerIDCard 按缴款人身份证搜索。
func (s *PaymentRecordService) SearchByPayerIDCard(idCard string, page int, size int) ([]domain.PaymentRecord, error) {
	return s.paymentPage(s.DB().Where("payer_id_card LIKE ?", like(idCard)), page, size)
}

// SearchByPaymentStatus 按支付状态搜索。
func (s *PaymentRecordService) SearchByPaymentStatus(status string, page int, size int) ([]domain.PaymentRecord, error) {
	return s.paymentPage(s.DB().Where("payment_status = ?", strings.TrimSpace(status)), page, size)
}

// SearchByTransactionID 按交易流水号搜索。
func (s *PaymentRecordService) SearchByTransactionID(transactionID string, page int, size int) ([]domain.PaymentRecord, error) {
	return s.paymentPage(s.DB().Where("transaction_id LIKE ?", like(transactionID)), page, size)
}

// SearchByPaymentNumber 按支付流水号搜索。
func (s *PaymentRecordService) SearchByPaymentNumber(paymentNumber string, page int, size int) ([]domain.PaymentRecord, error) {
	return s.paymentPage(s.DB().Where("payment_number LIKE ?", like(paymentNumber)), page, size)
}

// SearchByPayerName 按缴款人姓名搜索。
func (s *PaymentRecordService) SearchByPayerName(payerName string, page int, size int) ([]domain.PaymentRecord, error) {
	return s.paymentPage(s.DB().Where("payer_name LIKE ?", like(payerName)), page, size)
}

// SearchByPaymentMethod 按支付方式搜索。
func (s *PaymentRecordService) SearchByPaymentMethod(method string, page int, size int) ([]domain.PaymentRecord, error) {
	return s.paymentPage(s.DB().Where("payment_method = ?", strings.TrimSpace(method)), page, size)
}

// SearchByPaymentChannel 按支付渠道搜索。
func (s *PaymentRecordService) SearchByPaymentChannel(channel string, page int, size int) ([]domain.PaymentRecord, error) {
	return s.paymentPage(s.DB().Where("payment_channel = ?", strings.TrimSpace(channel)), page, size)
}

// SearchByPaymentTimeRange 按支付时间范围搜索，支持日期与日期时间两种格式。
func (s *PaymentRecordService) SearchByPaymentTimeRange(startTime string, endTime string, page int, size int) ([]domain.PaymentRecord, error) {
	start, err := parseFlexibleDateTime(startTime)
	if err != nil {
		return nil, err
	}
	end, err := parseFlexibleDateTime(endTime)
	if err != nil {
		return nil, err
	}
	return s.paymentPage(s.DB().Where("payment_time BETWEEN ? AND ?", start, end), page, size)
}

func (s *PaymentRecordService) paymentPage(query *gorm.DB, page int, size int) ([]domain.PaymentRecord, error) {
	offset, limit := pageBounds(page, size)
	var payments []domain.PaymentRecord
	err := query.Order("payment_id DESC").Offset(offset).Limit(limit).Find(&payments).Error
	return payments, err
}

// parseFlexibleDateTime 支持 yyyy-MM-dd 与 yyyy-MM-dd HH:mm[:ss] 及 ISO T 分隔。
func parseFlexibleDateTime(value string) (time.Time, error) {
	value = strings.TrimSpace(value)
	formats := []string{
		"2006-01-02 15:04:05",
		"2006-01-02T15:04:05",
		"2006-01-02T15:04:05Z07:00",
		"2006-01-02",
	}
	for _, format := range formats {
		if parsed, err := time.Parse(format, value); err == nil {
			return parsed, nil
		}
	}
	return time.Time{}, errors.New("invalid datetime: " + value)
}
