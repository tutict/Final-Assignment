package repo

import (
	"final_assignment_backend_go/project/internal/domain"

	"gorm.io/gorm"
)

// RefreshTokenRepo 提供 RefreshToken 的数据库操作。
type RefreshTokenRepo struct {
	db *gorm.DB
}

func NewRefreshTokenRepo(db *gorm.DB) *RefreshTokenRepo {
	return &RefreshTokenRepo{db: db}
}

// Insert 插入一条新的 refresh token 记录。
func (r *RefreshTokenRepo) Insert(t *domain.RefreshToken) error {
	return r.db.Create(t).Error
}

// FindByDigest 按 lookup_digest 查找一条未撤销且未过期的记录（O(1) 查找）。
func (r *RefreshTokenRepo) FindByDigest(digest string) (*domain.RefreshToken, error) {
	var t domain.RefreshToken
	err := r.db.Where("lookup_digest = ? AND revoked = ? AND expires_at > ?",
		digest, false, gorm.Expr("NOW()")).First(&t).Error
	return &t, err
}

// FindLegacyCandidates 查找历史无 digest 的未撤销未过期记录（一次性迁移）。
func (r *RefreshTokenRepo) FindLegacyCandidates(limit int) ([]domain.RefreshToken, error) {
	var tokens []domain.RefreshToken
	err := r.db.Where("revoked = ? AND expires_at > ? AND lookup_digest IS NULL",
		false, gorm.Expr("NOW()")).Limit(limit).Find(&tokens).Error
	return tokens, err
}

// Update 更新记录（回填 digest 等）。
func (r *RefreshTokenRepo) Update(t *domain.RefreshToken) error {
	return r.db.Save(t).Error
}

// RevokeByID 用乐观锁（id + revoked=false）撤销指定记录，返回受影响行数。
func (r *RefreshTokenRepo) RevokeByID(id int64) (int64, error) {
	result := r.db.Model(&domain.RefreshToken{}).
		Where("id = ? AND revoked = ?", id, false).
		Update("revoked", true)
	return result.RowsAffected, result.Error
}

// RevokeByUser 撤销某用户全部未撤销的 refresh token。
func (r *RefreshTokenRepo) RevokeByUser(userID uint64) error {
	return r.db.Model(&domain.RefreshToken{}).
		Where("user_id = ? AND revoked = ?", userID, false).
		Update("revoked", true).Error
}
