package service

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"log"
	"time"

	"github.com/redis/go-redis/v9"
)

// access-token 黑名单（登出即撤销）。以 token 的 SHA-256 为 key 存入 Redis，
// TTL 等于该 token 的剩余寿命，到期自动清理。对齐 Spring/Quarkus 的 TokenBlacklistService。
//
// fail-open=false（默认）时，Redis 不可用即拒绝校验，避免放行已撤销 token；
// fail-open=true 时放行并仅记录告警（与 Spring 语义一致）。
type TokenBlacklistService struct {
	client                 *redis.Client
	failOpenWhenUnavailable bool
	ctx                    context.Context
}

// NewTokenBlacklistService 构造黑名单服务。failOpenWhenUnavailable=false 时 Redis 不可用即报错。
func NewTokenBlacklistService(client *redis.Client, failOpenWhenUnavailable bool) *TokenBlacklistService {
	return &TokenBlacklistService{
		client:                  client,
		failOpenWhenUnavailable: failOpenWhenUnavailable,
		ctx:                      context.Background(),
	}
}

// Blacklist 把 access token 加入黑名单，TTL 等于其剩余寿命（毫秒）。
func (b *TokenBlacklistService) Blacklist(token string, ttlMillis int64) {
	if token == "" || ttlMillis <= 0 {
		return
	}
	ttl := time.Duration(ttlMillis) * time.Millisecond
	if err := b.client.Set(b.ctx, b.key(token), "revoked", ttl).Err(); err != nil {
		if b.failOpenWhenUnavailable {
			log.Printf("[WARN] Failed to blacklist access token because Redis is unavailable: %v", err)
			return
		}
		log.Printf("[ERROR] Failed to blacklist access token: %v", err)
	}
}

// IsBlacklisted 检查 access token 是否已被撤销。
// Redis 不可用时：fail-open=true 返回 false（放行），fail-open=false 返回 true（拒绝，更安全）。
func (b *TokenBlacklistService) IsBlacklisted(token string) bool {
	if token == "" {
		return false
	}
	n, err := b.client.Exists(b.ctx, b.key(token)).Result()
	if err != nil {
		log.Printf("[ERROR] Failed to check access token blacklist: %v", err)
		return !b.failOpenWhenUnavailable
	}
	return n > 0
}

func (b *TokenBlacklistService) key(token string) string {
	sum := sha256.Sum256([]byte(token))
	return "blacklist:" + hex.EncodeToString(sum[:])
}

// ErrRedisUnavailable 保留以对齐 Spring 语义（当前未直接使用）。
var ErrRedisUnavailable = errors.New("redis unavailable")
