package redisconfig

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"os"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

// RedisConfig 配置结构体
const (
	cacheCommandTimeout     = 300 * time.Millisecond
	blacklistCommandTimeout = 200 * time.Millisecond
)

type RedisConfig struct {
	Host        string
	Port        string
	DB          int
	Timeout     time.Duration
	CachePrefix string
	Client      *redis.Client
	Blacklist   *redis.Client
	Ctx         context.Context
}

// NewRedisConfig 从环境变量初始化配置（类似 Spring @Value）
func NewRedisConfig() *RedisConfig {
	host := os.Getenv("REDIS_HOST")
	if host == "" {
		host = "localhost"
	}
	if strings.EqualFold(os.Getenv("REDIS_ENABLED"), "false") {
		host = ""
	}

	port := os.Getenv("REDIS_PORT")
	if port == "" {
		port = "6379"
	}

	timeout := 10 * time.Second
	if val := os.Getenv("REDIS_TIMEOUT"); val != "" {
		if d, err := time.ParseDuration(val); err == nil {
			timeout = d
		}
	}

	return &RedisConfig{
		Host:        host,
		Port:        port,
		DB:          0,
		Timeout:     timeout,
		CachePrefix: "app-cache:",
		Ctx:         context.Background(),
	}
}

// InitRedis 初始化 Redis 客户端（类似于 redisConnectionFactory）
func (r *RedisConfig) InitRedis() error {
	if r.Host == "" {
		disabled := redis.NewClient(&redis.Options{Addr: "disabled"})
		r.Client = disabled
		r.Blacklist = disabled
		current = r
		log.Println("[INFO] Redis disabled (REDIS_ENABLED=false), using no-op client")
		return nil
	}

	client := redis.NewClient(redisOptions(r, cacheCommandTimeout))
	blacklist := redis.NewClient(redisOptions(r, blacklistCommandTimeout))

	// 测试连接
	if err := client.Ping(r.Ctx).Err(); err != nil {
		return err
	}

	r.Client = client
	r.Blacklist = blacklist
	current = r
	log.Printf("[INFO] Connected to Redis at %s:%s\n", r.Host, r.Port)
	return nil
}

func redisOptions(r *RedisConfig, commandTimeout time.Duration) *redis.Options {
	return &redis.Options{
		Addr:                  r.Host + ":" + r.Port,
		DB:                    r.DB,
		DialTimeout:           200 * time.Millisecond,
		ReadTimeout:           commandTimeout,
		WriteTimeout:          commandTimeout,
		MaxRetries:            1,
		ContextTimeoutEnabled: true,
	}
}

// RedisSetJSON 设置缓存，带序列化与过期时间
func (r *RedisConfig) RedisSetJSON(key string, value interface{}, ttl time.Duration) error {
	data, err := json.Marshal(value)
	if err != nil {
		return err
	}
	fullKey := r.CachePrefix + key
	return r.Client.Set(r.Ctx, fullKey, data, ttl).Err()
}

// RedisGetJSON 获取缓存并反序列化
func (r *RedisConfig) RedisGetJSON(key string, dest interface{}) error {
	fullKey := r.CachePrefix + key
	data, err := r.Client.Get(r.Ctx, fullKey).Bytes()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return nil // 缓存不存在
		}
		return err
	}
	return json.Unmarshal(data, dest)
}

// RedisDelete 删除缓存
func (r *RedisConfig) RedisDelete(key string) error {
	fullKey := r.CachePrefix + key
	return r.Client.Del(r.Ctx, fullKey).Err()
}

// RedisCacheManager 简易封装：自动管理过期时间、序列化、前缀
type RedisCacheManager struct {
	Config *RedisConfig
	TTL    time.Duration
}

// NewRedisCacheManager 创建缓存管理器（类似于 RedisCacheManager bean）
func NewRedisCacheManager(config *RedisConfig, ttl time.Duration) *RedisCacheManager {
	return &RedisCacheManager{
		Config: config,
		TTL:    ttl,
	}
}

// Set 缓存对象
func (cm *RedisCacheManager) Set(key string, value interface{}) error {
	return cm.Config.RedisSetJSON(key, value, cm.TTL)
}

// Get 从缓存获取对象
func (cm *RedisCacheManager) Get(key string, dest interface{}) error {
	return cm.Config.RedisGetJSON(key, dest)
}

// Delete 删除缓存
func (cm *RedisCacheManager) Delete(key string) error {
	return cm.Config.RedisDelete(key)
}

var current *RedisConfig

// Current returns the process Redis client after InitRedis.
func Current() *RedisConfig {
	return current
}

// ClearCachePrefix deletes application cache keys without touching the token blacklist.
func (r *RedisConfig) ClearCachePrefix() error {
	if r == nil || r.Client == nil || r.Host == "" {
		return nil
	}
	var cursor uint64
	pattern := r.CachePrefix + "*"
	for {
		keys, next, err := r.Client.Scan(r.Ctx, cursor, pattern, 200).Result()
		if err != nil {
			return err
		}
		if len(keys) > 0 {
			if err := r.Client.Del(r.Ctx, keys...).Err(); err != nil {
				return err
			}
		}
		cursor = next
		if cursor == 0 {
			return nil
		}
	}
}
