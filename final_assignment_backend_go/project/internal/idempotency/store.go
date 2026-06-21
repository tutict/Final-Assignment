package idempotency

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

var (
	// ErrAlreadyProcessing indicates the request is already being processed
	ErrAlreadyProcessing = errors.New("request already in progress")
	// ErrStoreFailed indicates the store operation failed
	ErrStoreFailed = errors.New("idempotency store operation failed")
)

// Store defines the interface for idempotency storage
type Store interface {
	// MarkProcessing marks a key as being processed
	// Returns false if already processing
	MarkProcessing(ctx context.Context, key string, ttl time.Duration) (bool, error)

	// MarkCompleted marks a key as completed with result
	MarkCompleted(ctx context.Context, key string, result interface{}, ttl time.Duration) error

	// GetResult retrieves the result for a key
	// Returns (result, completed, error)
	GetResult(ctx context.Context, key string) (interface{}, bool, error)

	// Delete removes a key from the store
	Delete(ctx context.Context, key string) error
}

// RedisStore implements Store using Redis
type RedisStore struct {
	client *redis.Client
	prefix string
}

// NewRedisStore creates a new Redis-backed idempotency store
func NewRedisStore(client *redis.Client, prefix string) *RedisStore {
	if prefix == "" {
		prefix = "idempotency"
	}
	return &RedisStore{
		client: client,
		prefix: prefix,
	}
}

// MarkProcessing marks a key as being processed
func (rs *RedisStore) MarkProcessing(ctx context.Context, key string, ttl time.Duration) (bool, error) {
	fullKey := rs.fullKey(key)

	// Use SETNX to atomically set only if not exists
	result, err := rs.client.SetNX(ctx, fullKey, "PROCESSING", ttl).Result()
	if err != nil {
		return false, fmt.Errorf("%w: %v", ErrStoreFailed, err)
	}

	return result, nil
}

// MarkCompleted marks a key as completed with result
func (rs *RedisStore) MarkCompleted(ctx context.Context, key string, result interface{}, ttl time.Duration) error {
	fullKey := rs.fullKey(key)

	// Serialize result
	data := map[string]interface{}{
		"status":      "COMPLETED",
		"result":      result,
		"completedAt": time.Now().Unix(),
	}

	jsonData, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("failed to marshal result: %w", err)
	}

	// Set with TTL
	err = rs.client.Set(ctx, fullKey, jsonData, ttl).Err()
	if err != nil {
		return fmt.Errorf("%w: %v", ErrStoreFailed, err)
	}

	return nil
}

// GetResult retrieves the result for a key
func (rs *RedisStore) GetResult(ctx context.Context, key string) (interface{}, bool, error) {
	fullKey := rs.fullKey(key)

	val, err := rs.client.Get(ctx, fullKey).Result()
	if err == redis.Nil {
		// Key doesn't exist
		return nil, false, nil
	}
	if err != nil {
		return nil, false, fmt.Errorf("%w: %v", ErrStoreFailed, err)
	}

	// If still processing
	if val == "PROCESSING" {
		return nil, false, nil
	}

	// Parse completed result
	var data map[string]interface{}
	if err := json.Unmarshal([]byte(val), &data); err != nil {
		return nil, false, fmt.Errorf("failed to unmarshal result: %w", err)
	}

	result, ok := data["result"]
	if !ok {
		return nil, false, errors.New("result not found in stored data")
	}

	return result, true, nil
}

// Delete removes a key from the store
func (rs *RedisStore) Delete(ctx context.Context, key string) error {
	fullKey := rs.fullKey(key)
	return rs.client.Del(ctx, fullKey).Err()
}

// fullKey returns the full key with prefix
func (rs *RedisStore) fullKey(key string) string {
	return fmt.Sprintf("%s:%s", rs.prefix, key)
}

// MemoryStore implements Store using in-memory map (for testing)
type MemoryStore struct {
	data map[string]storeEntry
}

type storeEntry struct {
	value     interface{}
	expiresAt time.Time
}

// NewMemoryStore creates a new in-memory idempotency store
func NewMemoryStore() *MemoryStore {
	return &MemoryStore{
		data: make(map[string]storeEntry),
	}
}

// MarkProcessing marks a key as being processed
func (ms *MemoryStore) MarkProcessing(ctx context.Context, key string, ttl time.Duration) (bool, error) {
	// Check if exists and not expired
	if entry, exists := ms.data[key]; exists {
		if time.Now().Before(entry.expiresAt) {
			return false, nil // Already processing
		}
		// Expired, remove it
		delete(ms.data, key)
	}

	ms.data[key] = storeEntry{
		value:     "PROCESSING",
		expiresAt: time.Now().Add(ttl),
	}

	return true, nil
}

// MarkCompleted marks a key as completed with result
func (ms *MemoryStore) MarkCompleted(ctx context.Context, key string, result interface{}, ttl time.Duration) error {
	data := map[string]interface{}{
		"status":      "COMPLETED",
		"result":      result,
		"completedAt": time.Now().Unix(),
	}

	ms.data[key] = storeEntry{
		value:     data,
		expiresAt: time.Now().Add(ttl),
	}

	return nil
}

// GetResult retrieves the result for a key
func (ms *MemoryStore) GetResult(ctx context.Context, key string) (interface{}, bool, error) {
	entry, exists := ms.data[key]
	if !exists {
		return nil, false, nil
	}

	// Check expiration
	if time.Now().After(entry.expiresAt) {
		delete(ms.data, key)
		return nil, false, nil
	}

	// If still processing
	if entry.value == "PROCESSING" {
		return nil, false, nil
	}

	// Extract result from completed entry
	if dataMap, ok := entry.value.(map[string]interface{}); ok {
		result, ok := dataMap["result"]
		if !ok {
			return nil, false, errors.New("result not found in stored data")
		}
		return result, true, nil
	}

	return nil, false, errors.New("invalid stored data format")
}

// Delete removes a key from the store
func (ms *MemoryStore) Delete(ctx context.Context, key string) error {
	delete(ms.data, key)
	return nil
}

// Clear removes all entries (for testing)
func (ms *MemoryStore) Clear() {
	ms.data = make(map[string]storeEntry)
}
