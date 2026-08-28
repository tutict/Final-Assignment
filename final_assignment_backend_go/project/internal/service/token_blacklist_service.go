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
	client                  *redis.Client
	failOpenWhenUnavailable bool
	ctx                     context.Context
	// callTimeout 限制单次 Redis 调用的应用级超时，避免慢/拥塞 Redis 拖垮每个鉴权请求。
	// 0 表示无应用级超时（退化为 socket ReadTimeout）。
	callTimeout time.Duration
}

// NewTokenBlacklistService 构造黑名单服务。failOpenWhenUnavailable=false 时 Redis 不可用即报错。
func NewTokenBlacklistService(client *redis.Client, failOpenWhenUnavailable bool) *TokenBlacklistService {
	return &TokenBlacklistService{
		client:                  client,
		failOpenWhenUnavailable: failOpenWhenUnavailable,
		ctx:                     context.Background(),
		// 每次鉴权都查黑名单，给一个短于 socket 超时的应用级上限，防慢 Redis 拖垮热路径。
		callTimeout: 2 * time.Second,
	}
}

// Blacklist 把 access token 加入黑名单，TTL 等于其剩余寿命（毫秒）。
// fail-open=false 时若 Redis 不可用返回错误，调用方应据此返回失败响应，避免"登出成功但未撤销"。
func (b *TokenBlacklistService) Blacklist(token string, ttlMillis int64) error {
	if token == "" || ttlMillis <= 0 {
		return nil
	}
	ttl := time.Duration(ttlMillis) * time.Millisecond
	ctx, cancel := b.callCtx()
	defer cancel()
	if err := b.client.Set(ctx, b.key(token), "revoked", ttl).Err(); err != nil {
		if b.failOpenWhenUnavailable {
			log.Printf("[WARN] Failed to blacklist access token because Redis is unavailable: %v", err)
			return nil
		}
		log.Printf("[ERROR] Failed to blacklist access token: %v", err)
		return ErrRedisUnavailable
	}
	return nil
}

// IsBlacklisted 检查 access token 是否已被撤销。
// Redis 不可用时：fail-open=true 返回 false（放行），fail-open=false 返回 true（拒绝，更安全）。
func (b *TokenBlacklistService) IsBlacklisted(token string) bool {
	if token == "" {
		return false
	}
	ctx, cancel := b.callCtx()
	defer cancel()
	n, err := b.client.Exists(ctx, b.key(token)).Result()
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

// callCtx 返回带应用级超时的 context；callTimeout<=0 时退化为基础 ctx。
func (b *TokenBlacklistService) callCtx() (context.Context, context.CancelFunc) {
	if b.callTimeout > 0 {
		return context.WithTimeout(b.ctx, b.callTimeout)
	}
	return b.ctx, func() {}
}

// ErrRedisUnavailable 表示 Redis 不可用且 fail-open 关闭时拒绝写黑名单。
var ErrRedisUnavailable = errors.New("redis unavailable")
