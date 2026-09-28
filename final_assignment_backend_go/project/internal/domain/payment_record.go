package domain

import (
	"time"

	"gorm.io/gorm"
)

// PaymentRecord 表示 payment_record 表的实体，对齐 Spring 的
// com.tutict.finalassignmentbackend.entity.payment.PaymentRecord
type PaymentRecord struct {
	PaymentID      int64      `gorm:"column:payment_id;primaryKey;autoIncrement" json:"paymentId"`
	FineID         int64      `gorm:"column:fine_id" json:"fineId"`
	DriverID       *int64     `gorm:"column:driver_id" json:"driverId"`
	PaymentNumber  string     `gorm:"column:payment_number" json:"paymentNumber"`
	PaymentAmount  float64    `gorm:"column:payment_amount" json:"paymentAmount"`
	PaymentMethod  string     `gorm:"column:payment_method" json:"paymentMethod"`
	PaymentTime    *time.Time `gorm:"column:payment_time" json:"paymentTime"`
	PaymentChannel string     `gorm:"column:payment_channel" json:"paymentChannel"`
	PayerName      string     `gorm:"column:payer_name" json:"payerName"`
	PayerIDCard    string     `gorm:"column:payer_id_card" json:"payerIdCard"`
	// 敏感密文列与 Spring 保持同库同列，但不在响应中序列化（对齐 @JsonIgnore）
	PayerIDCardCiphertext  string         `gorm:"column:payer_id_card_ciphertext" json:"-"`
	PayerIDCardBlindIndex  string         `gorm:"column:payer_id_card_blind_index" json:"-"`
	PayerContact           string         `gorm:"column:payer_contact" json:"payerContact"`
	PayerContactCiphertext string         `gorm:"column:payer_contact_ciphertext" json:"-"`
	PayerContactBlindIndex string         `gorm:"column:payer_contact_blind_index" json:"-"`
	BankName               string         `gorm:"column:bank_name" json:"bankName"`
	BankAccount            string         `gorm:"column:bank_account" json:"bankAccount"`
	BankAccountCiphertext  string         `gorm:"column:bank_account_ciphertext" json:"-"`
	BankAccountBlindIndex  string         `gorm:"column:bank_account_blind_index" json:"-"`
	TransactionID          string         `gorm:"column:transaction_id" json:"transactionId"`
	ReceiptNumber          string         `gorm:"column:receipt_number" json:"receiptNumber"`
	ReceiptURL             string         `gorm:"column:receipt_url" json:"receiptUrl"`
	PaymentStatus          string         `gorm:"column:payment_status" json:"paymentStatus"`
	Version                *int           `gorm:"column:version" json:"version"`
	RefundAmount           float64        `gorm:"column:refund_amount" json:"refundAmount"`
	RefundTime             *time.Time     `gorm:"column:refund_time" json:"refundTime"`
	CreatedAt              *time.Time     `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt              *time.Time     `gorm:"column:updated_at" json:"updatedAt"`
	CreatedBy              string         `gorm:"column:created_by" json:"createdBy"`
	UpdatedBy              string         `gorm:"column:updated_by" json:"updatedBy"`
	DeletedAt              gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
	Remarks                string         `gorm:"column:remarks" json:"remarks"`
}

// TableName 指定数据库表名
func (PaymentRecord) TableName() string {
	return "payment_record"
}
