package redisconfig

import (
	"testing"
	"time"
)

func TestRedisCommandTimeouts(t *testing.T) {
	if cacheCommandTimeout != 300*time.Millisecond {
		t.Fatalf("cache=%s", cacheCommandTimeout)
	}
	if blacklistCommandTimeout != 200*time.Millisecond {
		t.Fatalf("blacklist=%s", blacklistCommandTimeout)
	}
	cache := redisOptions(&RedisConfig{Host: "127.0.0.1", Port: "6379"}, cacheCommandTimeout)
	blacklist := redisOptions(&RedisConfig{Host: "127.0.0.1", Port: "6379"}, blacklistCommandTimeout)
	if cache.ReadTimeout != 300*time.Millisecond || cache.WriteTimeout != 300*time.Millisecond {
		t.Fatalf("cache options read=%s write=%s", cache.ReadTimeout, cache.WriteTimeout)
	}
	if blacklist.ReadTimeout != 200*time.Millisecond || blacklist.WriteTimeout != 200*time.Millisecond {
		t.Fatalf("blacklist options read=%s write=%s", blacklist.ReadTimeout, blacklist.WriteTimeout)
	}
	if cache.MaxRetries != 1 || blacklist.MaxRetries != 1 {
		t.Fatalf("retries cache=%d blacklist=%d", cache.MaxRetries, blacklist.MaxRetries)
	}
	if cache.DialTimeout != 200*time.Millisecond || blacklist.DialTimeout != 200*time.Millisecond {
		t.Fatalf("dial cache=%s blacklist=%s", cache.DialTimeout, blacklist.DialTimeout)
	}
}
