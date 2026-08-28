package service

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"time"

	"final_assignment_backend_go/project/internal/auth"
	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

// refresh-token-lookup-v1 与 Spring/Quarkus 的 HMAC_KEY 一致，以便跨后端共用 digest 语义。
const refreshHMACKey = "refresh-token-lookup-v1"

var (
	errRefreshTokenRequired = errors.New("refresh token is required")
	errInvalidRefreshToken  = errors.New("invalid refresh token")
	errRefreshAlreadyUsed   = errors.New("refresh token has already been used")
)

// RefreshTokenService 签发 / 校验 / 轮换 / 撤销刷新令牌。令牌以 ML-KEM 信封
// （*auth.PqcTokenCrypto）后量子加密后落库，明文只在签发时返回给客户端。
// 查找优化：存储时额外写 lookup_digest（HMAC-SHA-256(raw)），校验/轮换先按 digest 做 O(1)
// 单行查询；历史无 digest 的令牌回落到全表扫描并回填 digest（一次性迁移）。
// 对齐 Spring/Quarkus 的 RefreshTokenService。
type RefreshTokenService struct {
	repo                     *repo.RefreshTokenRepo
	crypto                   *auth.PqcTokenCrypto
	refreshExpirationSeconds int64
}

// NewRefreshTokenService 构造 RefreshTokenService。refreshExpirationSeconds<=0 时默认 7 天。
func NewRefreshTokenService(r *repo.RefreshTokenRepo, c *auth.PqcTokenCrypto, refreshExpirationSeconds int64) *RefreshTokenService {
	if refreshExpirationSeconds <= 0 {
		refreshExpirationSeconds = 7 * 24 * 3600
	}
	return &RefreshTokenService{repo: r, crypto: c, refreshExpirationSeconds: refreshExpirationSeconds}
}

// CreateRefreshToken 为指定用户签发刷新令牌，返回明文令牌（仅此一次）。
func (s *RefreshTokenService) CreateRefreshToken(userID uint64) (string, error) {
	if userID == 0 {
		return "", errors.New("userId must not be zero")
	}
	return s.createRefreshTokenFor(userID)
}

// createRefreshTokenFor 实际签发逻辑：生成明文、ML-KEM 加密、构造实体并落库。
func (s *RefreshTokenService) createRefreshTokenFor(userID uint64) (string, error) {
	raw := generateRawToken()
	now := time.Now()
	enc, err := s.crypto.Encrypt(raw)
	if err != nil {
		return "", err
	}
	entity := &domain.RefreshToken{
		Token:        enc,
		LookupDigest: s.computeDigest(raw),
		UserID:       userID,
		ExpiresAt:    now.Add(time.Duration(s.refreshExpirationSeconds) * time.Second),
		Revoked:      false,
		CreatedAt:    now,
	}
	if err := s.repo.Insert(entity); err != nil {
		return "", err
	}
	return raw, nil
}

// ValidateRefreshToken 校验原始令牌，返回关联用户 ID。
func (s *RefreshTokenService) ValidateRefreshToken(raw string) (uint64, error) {
	t, err := s.requireActiveToken(raw)
	if err != nil {
		return 0, err
	}
	return t.UserID, nil
}

// RotateRefreshToken 用一次即换：撤销旧令牌并签发新令牌。并发场景靠乐观锁保证单次消费。
// 撤销与签发在同一事务内完成：若签发失败（DB 抖动 / ML-KEM 加密失败 / 唯一索引冲突），
// 撤销随之回滚，避免旧令牌已作废但新令牌未签发导致用户被静默强制登出。对齐 Spring/Quarkus
// 的 @Transactional rotateRefreshToken 语义。
func (s *RefreshTokenService) RotateRefreshToken(userID uint64, raw string) (string, error) {
	existing, err := s.requireActiveToken(raw)
	if err != nil {
		return "", err
	}
	if existing.UserID != userID {
		return "", errInvalidRefreshToken
	}

	var newRaw string
	txErr := s.repo.DB().Transaction(func(tx *gorm.DB) error {
		rows, rerr := s.repo.RevokeByIDTx(tx, existing.ID)
		if rerr != nil {
			return rerr
		}
		if rows == 0 {
			return errRefreshAlreadyUsed
		}
		// 在事务内签发新令牌（加密在事务外亦可，但放事务内便于整体回滚）。
		raw, cerr := s.createRefreshTokenFor(userID)
		if cerr != nil {
			return cerr
		}
		newRaw = raw
		return nil
	})
	if txErr != nil {
		return "", txErr
	}
	return newRaw, nil
}

// RevokeUserTokens 撤销某用户全部未撤销的刷新令牌（登出时调用）。
func (s *RefreshTokenService) RevokeUserTokens(userID uint64) error {
	if userID == 0 {
		return nil
	}
	return s.repo.RevokeByUser(userID)
}

// GetRefreshTokenExpirationSeconds 返回 refresh token 有效期（秒）。
func (s *RefreshTokenService) GetRefreshTokenExpirationSeconds() int64 {
	return s.refreshExpirationSeconds
}

func (s *RefreshTokenService) requireActiveToken(raw string) (*domain.RefreshToken, error) {
	if raw == "" {
		return nil, errRefreshTokenRequired
	}
	digest := s.computeDigest(raw)

	// O(1) lookup by digest
	t, err := s.repo.FindByDigest(digest)
	if err == nil && t != nil && t.ID != 0 {
		if decrypted, derr := s.crypto.Decrypt(t.Token); derr == nil &&
			s.crypto.ConstantTimeEquals(raw, decrypted) {
			return t, nil
		}
	}

	// Fallback: legacy lookup without digest (one-time migration support)
	candidates, lerr := s.repo.FindLegacyCandidates(100)
	if lerr != nil {
		return nil, errInvalidRefreshToken
	}
	for _, candidate := range candidates {
		decrypted, derr := s.crypto.Decrypt(candidate.Token)
		if derr != nil {
			continue
		}
		if subtle.ConstantTimeCompare([]byte(raw), []byte(decrypted)) != 1 {
			continue
		}
		// Backfill the digest for future O(1) lookups
		candidate.LookupDigest = digest
		_ = s.repo.Update(&candidate)
		return &candidate, nil
	}
	return nil, errInvalidRefreshToken
}

func (s *RefreshTokenService) computeDigest(raw string) string {
	mac := hmac.New(newSHA256, []byte(refreshHMACKey))
	mac.Write([]byte(raw))
	return hex.EncodeToString(mac.Sum(nil))
}

func generateRawToken() string {
	b := make([]byte, 32)
	_, _ = rand.Read(b)
	return base64.URLEncoding.WithPadding(base64.NoPadding).EncodeToString(b)
}
