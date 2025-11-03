package auth

import (
	"encoding/base64"
	"errors"
	"log"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// TokenProvider 是 JWT 令牌服务，负责创建、验证与解析 Token。
type TokenProvider struct {
	SecretKey []byte
}

// Init 从 base64 编码的字符串初始化密钥（对应 Java @PostConstruct）
func (p *TokenProvider) Init(base64Secret string) error {
	keyBytes, err := base64.StdEncoding.DecodeString(base64Secret)
	if err != nil {
		return err
	}
	p.SecretKey = keyBytes
	log.Println("[INFO] TokenProvider initialized with HS256 secret key")
	return nil
}

// CreateToken 创建 JWT，含用户名与角色（有效期 24 小时）
func (p *TokenProvider) CreateToken(username string, roles string) (string, error) {
	now := time.Now()
	expiration := now.Add(24 * time.Hour)

	claims := jwt.MapClaims{
		"sub":   username,
		"roles": roles,
		"iat":   now.Unix(),
		"exp":   expiration.Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(p.SecretKey)
}

// ValidateToken 验证 Token 签名与有效期
func (p *TokenProvider) ValidateToken(tokenString string) bool {
	_, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		return p.SecretKey, nil
	})
	if err != nil {
		log.Printf("[WARN] Invalid token: %v", err)
		return false
	}
	log.Printf("[INFO] Token validated successfully: %s", tokenString)
	return true
}

// ExtractRoles 从 Token 中解析角色列表
func (p *TokenProvider) ExtractRoles(tokenString string) ([]string, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		return p.SecretKey, nil
	})
	if err != nil {
		log.Printf("[WARN] Failed to parse roles from token: %v", err)
		return nil, err
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok {
		rawRoles, ok := claims["roles"].(string)
		if !ok || rawRoles == "" {
			return []string{}, nil
		}

		parts := strings.Split(rawRoles, ",")
		roles := make([]string, 0, len(parts))
		for _, r := range parts {
			r = strings.TrimSpace(r)
			if !strings.HasPrefix(r, "ROLE_") {
				r = "ROLE_" + r
			}
			roles = append(roles, r)
		}
		return roles, nil
	}

	return []string{}, errors.New("invalid claims structure")
}

// GetUsernameFromToken 从 JWT 中提取用户名
func (p *TokenProvider) GetUsernameFromToken(tokenString string) (string, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		return p.SecretKey, nil
	})
	if err != nil {
		return "", err
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok {
		sub, ok := claims["sub"].(string)
		if ok {
			return sub, nil
		}
	}
	return "", errors.New("subject (username) not found in token")
}
