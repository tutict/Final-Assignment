package redisconfig

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"os"
	"time"

	"github.com/redis/go-redis/v9"
)

// RedisConfig 配置结构体
type RedisConfig struct {
	Host        string
	Port        string
	DB          int
	Timeout     time.Duration
	CachePrefix string
	Client      *redis.Client
	Ctx         context.Context
}

// NewRedisConfig 从环境变量初始化配置（类似 Spring @Value）
func NewRedisConfig() *RedisConfig {
	host := os.Getenv("REDIS_HOST")
	if host == "" {
		host = "localhost"
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
	opt := &redis.Options{
		Addr:         r.Host + ":" + r.Port,
		DB:           r.DB,
		ReadTimeout:  r.Timeout,
		WriteTimeout: r.Timeout,
	}

	client := redis.NewClient(opt)

	// 测试连接
	if err := client.Ping(r.Ctx).Err(); err != nil {
		return err
	}

	r.Client = client
	log.Printf("[INFO] Connected to Redis at %s:%s\n", r.Host, r.Port)
	return nil
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
