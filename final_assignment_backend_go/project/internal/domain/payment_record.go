package domain

import (
	"time"

	"gorm.io/gorm"
)

// PaymentRecord 表示 payment_record 表的实体，对齐 Spring 的
// com.tutict.finalassignmentbackend.entity.payment.PaymentRecord
type PaymentRecord struct {
	PaymentID      int64      `gorm:"column:payment_id;primaryKey;autoIncrement" json:"payment_id"`
	FineID         int64      `gorm:"column:fine_id" json:"fine_id"`
	DriverID       *int64     `gorm:"column:driver_id" json:"driver_id"`
	PaymentNumber  string     `gorm:"column:payment_number" json:"payment_number"`
	PaymentAmount  float64    `gorm:"column:payment_amount" json:"payment_amount"`
	PaymentMethod  string     `gorm:"column:payment_method" json:"payment_method"`
	PaymentTime    *time.Time `gorm:"column:payment_time" json:"payment_time"`
	PaymentChannel string     `gorm:"column:payment_channel" json:"payment_channel"`
	PayerName      string     `gorm:"column:payer_name" json:"payer_name"`
	PayerIDCard    string     `gorm:"column:payer_id_card" json:"payer_id_card"`
	// 敏感密文列与 Spring 保持同库同列，但不在响应中序列化（对齐 @JsonIgnore）
	PayerIDCardCiphertext  string         `gorm:"column:payer_id_card_ciphertext" json:"-"`
	PayerIDCardBlindIndex  string         `gorm:"column:payer_id_card_blind_index" json:"-"`
	PayerContact           string         `gorm:"column:payer_contact" json:"payer_contact"`
	PayerContactCiphertext string         `gorm:"column:payer_contact_ciphertext" json:"-"`
	PayerContactBlindIndex string         `gorm:"column:payer_contact_blind_index" json:"-"`
	BankName               string         `gorm:"column:bank_name" json:"bank_name"`
	BankAccount            string         `gorm:"column:bank_account" json:"bank_account"`
	BankAccountCiphertext  string         `gorm:"column:bank_account_ciphertext" json:"-"`
	BankAccountBlindIndex  string         `gorm:"column:bank_account_blind_index" json:"-"`
	TransactionID          string         `gorm:"column:transaction_id" json:"transaction_id"`
	ReceiptNumber          string         `gorm:"column:receipt_number" json:"receipt_number"`
	ReceiptURL             string         `gorm:"column:receipt_url" json:"receipt_url"`
	PaymentStatus          string         `gorm:"column:payment_status" json:"payment_status"`
	Version                int            `gorm:"column:version" json:"version"`
	RefundAmount           float64        `gorm:"column:refund_amount" json:"refund_amount"`
	RefundTime             *time.Time     `gorm:"column:refund_time" json:"refund_time"`
	CreatedAt              *time.Time     `gorm:"column:created_at" json:"created_at"`
	UpdatedAt              *time.Time     `gorm:"column:updated_at" json:"updated_at"`
	CreatedBy              string         `gorm:"column:created_by" json:"created_by"`
	UpdatedBy              string         `gorm:"column:updated_by" json:"updated_by"`
	DeletedAt              gorm.DeletedAt `gorm:"column:deleted_at;index" json:"-"`
	Remarks                string         `gorm:"column:remarks" json:"remarks"`
}

// TableName 指定数据库表名
func (PaymentRecord) TableName() string {
	return "payment_record"
}
