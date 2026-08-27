package auth

import (
	"encoding/base64"
	"errors"
	"log"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Algorithm 标识 JWT 签名算法。
type Algorithm string

const (
	AlgorithmHS256    Algorithm = "HS256"
	AlgorithmMLDSA65 Algorithm = "ML-DSA-65"
)

// TokenProvider 是 JWT 令牌服务，负责创建、验证与解析 Token。
// 支持 HS256（默认，HMAC）与 ML-DSA-65（FIPS 204，后量子签名）两种算法，
// 对齐 Spring/Quarkus config/login/jwt/TokenProvider 的算法切换语义。
type TokenProvider struct {
	secretKey                 []byte
	algorithm                 Algorithm
	accessTokenExpiration      time.Duration
	mlDsaKeyRing              *MlDsaKeyRing
	mlDsaRotationEnabled      bool
	mlDsaRetention            time.Duration
	mlDsaRotationStopCh       chan struct{}
	mlDsaRotationInterval     time.Duration
}

// TokenProviderConfig 构造 TokenProvider 所需的全部参数。
type TokenProviderConfig struct {
	// Base64Secret HS256 模式下的 base64 编码 HMAC 密钥
	Base64Secret string
	// Algorithm 签名算法，HS256 或 ML-DSA-65
	Algorithm Algorithm
	// AccessTokenExpiration access token 有效期
	AccessTokenExpiration time.Duration
	// MlDsaKeyRing ML-DSA 模式下的密钥环；HS256 模式可 nil
	MlDsaKeyRing *MlDsaKeyRing
	// MlDsaRotationEnabled 是否启用在线轮换
	MlDsaRotationEnabled bool
	// MlDsaRotationInterval 轮换间隔
	MlDsaRotationInterval time.Duration
	// MlDsaRetention 旧密钥保留窗口（轮换后供双验）
	MlDsaRetention time.Duration
}

// NewTokenProvider 根据配置构造 TokenProvider 并完成初始化校验。
func NewTokenProvider(cfg TokenProviderConfig) (*TokenProvider, error) {
	if cfg.AccessTokenExpiration <= 0 {
		return nil, errors.New("access token expiration must be greater than 0")
	}
	p := &TokenProvider{
		algorithm:             cfg.Algorithm,
		accessTokenExpiration: cfg.AccessTokenExpiration,
		mlDsaKeyRing:          cfg.MlDsaKeyRing,
		mlDsaRotationEnabled:  cfg.MlDsaRotationEnabled,
		mlDsaRetention:        cfg.MlDsaRetention,
		mlDsaRotationInterval: cfg.MlDsaRotationInterval,
	}
	if p.mlDsaRetention <= 0 {
		p.mlDsaRetention = 24 * time.Hour
	}
	if p.mlDsaRotationInterval <= 0 {
		p.mlDsaRotationInterval = 168 * time.Hour
	}

	switch p.algorithm {
	case AlgorithmHS256:
		if cfg.Base64Secret == "" {
			return nil, errors.New("jwt.secret.key must be provided for HS256")
		}
		keyBytes, err := base64.StdEncoding.DecodeString(cfg.Base64Secret)
		if err != nil {
			// 兼容：值不是 base64 时按原始字节处理
			keyBytes = []byte(cfg.Base64Secret)
		}
		if cfg.Base64Secret == "CHANGE_ME_IN_PRODUCTION" || len(keyBytes) < 32 {
			return nil, errors.New("jwt.secret.key must be at least 32 bytes and not CHANGE_ME_IN_PRODUCTION")
		}
		p.secretKey = keyBytes
		log.Printf("[INFO] TokenProvider initialized with HS256, access token ttl=%s", p.accessTokenExpiration)
	case AlgorithmMLDSA65:
		if p.mlDsaKeyRing == nil || p.mlDsaKeyRing.ActivePrivateKey() == nil {
			return nil, errors.New("ML-DSA key ring has no active signing key; configure ml-dsa keys")
		}
		log.Printf("[INFO] TokenProvider initialized with ML-DSA-65, access token ttl=%s", p.accessTokenExpiration)
		if p.mlDsaRotationEnabled {
			p.mlDsaRotationStopCh = make(chan struct{})
			go p.runScheduledRotation()
		}
	default:
		return nil, errors.New("unsupported jwt algorithm: " + string(p.algorithm))
	}

	return p, nil
}

// runScheduledRotation 周期性轮换 ML-DSA 密钥。对齐 Spring @Scheduled 语义。
func (p *TokenProvider) runScheduledRotation() {
	ticker := time.NewTicker(p.mlDsaRotationInterval)
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:
			if _, _, err := p.mlDsaKeyRing.Rotate(p.mlDsaRetention); err != nil {
				log.Printf("[ERROR] Scheduled ML-DSA key rotation failed: %v", err)
			}
		case <-p.mlDsaRotationStopCh:
			return
		}
	}
}

// StopRotation 停止后台轮换 goroutine（优雅关闭时调用）。
func (p *TokenProvider) StopRotation() {
	if p.mlDsaRotationStopCh != nil {
		close(p.mlDsaRotationStopCh)
		p.mlDsaRotationStopCh = nil
	}
}

// CreateToken 创建 JWT，含用户名与角色。
func (p *TokenProvider) CreateToken(username string, roles string) (string, error) {
	now := time.Now()
	claims := p.baseClaims(username, roles, now)
	if p.algorithm == AlgorithmMLDSA65 {
		return BuildMLDSAToken(claims, p.mlDsaKeyRing)
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(p.secretKey)
}

// CreateEnhancedToken 创建含 roleTypes / dataScope 的增强 JWT。
func (p *TokenProvider) CreateEnhancedToken(username, roleCodes, roleTypes, dataScope string) (string, error) {
	now := time.Now()
	claims := p.baseClaims(username, roleCodes, now)
	if roleTypes != "" {
		claims["roleTypes"] = roleTypes
	}
	if dataScope != "" {
		claims["dataScope"] = dataScope
	}
	if p.algorithm == AlgorithmMLDSA65 {
		return BuildMLDSAToken(claims, p.mlDsaKeyRing)
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(p.secretKey)
}

func (p *TokenProvider) baseClaims(username, roles string, now time.Time) jwt.MapClaims {
	return jwt.MapClaims{
		"sub":   username,
		"jti":   newUUID(),
		"roles": roles,
		"iat":   now.Unix(),
		"exp":   now.Add(p.accessTokenExpiration).Unix(),
	}
}

// GetAccessTokenExpirationSeconds 返回 access token 有效期（秒）。
func (p *TokenProvider) GetAccessTokenExpirationSeconds() int64 {
	return int64(p.accessTokenExpiration / time.Second)
}

// GetExpirationMs 返回 token 距离过期的剩余毫秒数；无法解析或已过期时返回 0。
func (p *TokenProvider) GetExpirationMs(tokenString string) int64 {
	claims, err := p.parseClaims(tokenString)
	if err != nil {
		return 0
	}
	expF, ok := toFloat64(claims["exp"])
	if !ok {
		return 0
	}
	remaining := int64(expF*1000) - time.Now().UnixMilli()
	if remaining < 0 {
		return 0
	}
	return remaining
}

// ValidateToken 验证 Token 签名与有效期。
func (p *TokenProvider) ValidateToken(tokenString string) bool {
	_, err := p.parseClaims(tokenString)
	if err != nil {
		log.Printf("[WARN] Invalid token: %v", err)
		return false
	}
	log.Println("[INFO] Token validated successfully")
	return true
}

// ExtractRoles 从 Token 中解析角色列表（统一带 ROLE_ 前缀，对齐历史 Go 行为）。
func (p *TokenProvider) ExtractRoles(tokenString string) ([]string, error) {
	claims, err := p.parseClaims(tokenString)
	if err != nil {
		return nil, err
	}
	rawRoles, ok := claims["roles"].(string)
	if !ok || rawRoles == "" {
		return []string{}, nil
	}
	parts := strings.Split(rawRoles, ",")
	roles := make([]string, 0, len(parts))
	for _, r := range parts {
		r = strings.TrimSpace(r)
		if r == "" {
			continue
		}
		if !strings.HasPrefix(r, "ROLE_") {
			r = "ROLE_" + r
		}
		roles = append(roles, r)
	}
	return roles, nil
}

// GetUsernameFromToken 从 JWT 中提取用户名。
func (p *TokenProvider) GetUsernameFromToken(tokenString string) (string, error) {
	claims, err := p.parseClaims(tokenString)
	if err != nil {
		return "", err
	}
	sub, ok := claims["sub"].(string)
	if ok && strings.TrimSpace(sub) != "" {
		return sub, nil
	}
	return "", errors.New("subject (username) not found in token")
}

// Algorithm 返回当前签名算法。
func (p *TokenProvider) Algorithm() Algorithm { return p.algorithm }

func (p *TokenProvider) parseClaims(tokenString string) (jwt.MapClaims, error) {
	if p.algorithm == AlgorithmMLDSA65 {
		return ParseMLDSAToken(tokenString, p.mlDsaKeyRing)
	}
	claims := jwt.MapClaims{}
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return p.secretKey, nil
	})
	if err != nil {
		return nil, err
	}
	if token == nil || !token.Valid {
		return nil, errors.New("invalid token")
	}
	return claims, nil
}
