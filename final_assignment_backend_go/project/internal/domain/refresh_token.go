package domain

import "time"

// RefreshToken 对应 refresh_tokens 表的实体。token 列保存 ML-KEM 信封密文，
// lookup_digest 用于 O(1) 查找（对齐 Spring/Quarkus 的 RefreshToken 实体）。
//
// 注意：Go 端复用 Spring/Quarkus 共享的同一张 refresh_tokens 表，
// 表名/列名保持一致以便跨后端共用同一数据库 schema。
type RefreshToken struct {
	ID          int64     `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	Token       string    `gorm:"column:token" json:"token"`
	LookupDigest string   `gorm:"column:lookup_digest;uniqueIndex:idx_refresh_tokens_lookup_digest" json:"lookup_digest,omitempty"`
	UserID      uint64    `gorm:"column:user_id" json:"user_id"`
	ExpiresAt   time.Time `gorm:"column:expires_at" json:"expires_at"`
	Revoked     bool      `gorm:"column:revoked" json:"revoked"`
	CreatedAt   time.Time `gorm:"column:created_at" json:"created_at"`
}

// TableName 指定数据库表名（与 Spring/Quarkus 一致）。
func (RefreshToken) TableName() string {
	return "refresh_tokens"
}
