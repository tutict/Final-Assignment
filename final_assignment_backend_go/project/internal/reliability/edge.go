package reliability

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

const (
	loginAccountLimit = 8
	loginIPLimit      = 40
	loginWindow       = time.Minute
	loginLock         = 2 * time.Minute
)

func Trace() gin.HandlerFunc {
	return func(c *gin.Context) {
		traceID := c.GetHeader("X-Trace-Id")
		if traceID == "" {
			traceID = uuid.NewString()
		}
		c.Header("X-Trace-Id", traceID)
		c.Next()
	}
}

type loginBucket struct {
	stamps      []time.Time
	lockedUntil time.Time
}

func LoginRateLimit() gin.HandlerFunc {
	var mu sync.Mutex
	accounts := map[string]*loginBucket{}
	ips := map[string]*loginBucket{}
	return func(c *gin.Context) {
		now := time.Now()
		ip := c.RemoteIP()
		if ip == "" {
			ip = "unknown"
		}
		username := loginUsername(c)
		mu.Lock()
		defer mu.Unlock()
		if username != "" {
			if retry := reserveLogin(accounts, "account:"+username, loginAccountLimit, now); retry > 0 {
				rejectLogin(c, retry)
				return
			}
		}
		if retry := reserveLogin(ips, "ip:"+ip, loginIPLimit, now); retry > 0 {
			rejectLogin(c, retry)
			return
		}
		c.Next()
	}
}

func reserveLogin(buckets map[string]*loginBucket, key string, limit int, now time.Time) int {
	state := buckets[key]
	if state == nil {
		state = &loginBucket{}
		buckets[key] = state
	}
	if now.Before(state.lockedUntil) {
		return retryAfterSeconds(state.lockedUntil.Sub(now))
	}
	kept := state.stamps[:0]
	for _, stamp := range state.stamps {
		if now.Sub(stamp) < loginWindow {
			kept = append(kept, stamp)
		}
	}
	state.stamps = kept
	if len(state.stamps) >= limit {
		state.lockedUntil = now.Add(loginLock)
		state.stamps = nil
		return int(loginLock.Seconds())
	}
	state.stamps = append(state.stamps, now)
	return 0
}

func retryAfterSeconds(remaining time.Duration) int {
	seconds := int((remaining + time.Second - 1) / time.Second)
	if seconds < 1 {
		return 1
	}
	return seconds
}

func rejectLogin(c *gin.Context, retryAfter int) {
	c.Header("Retry-After", itoa(retryAfter))
	c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
		"success":           false,
		"errorCode":         "LOGIN_RATE_LIMITED",
		"retryAfterSeconds": retryAfter,
	})
}

func loginUsername(c *gin.Context) string {
	if c.Request == nil || c.Request.Body == nil {
		return ""
	}
	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		c.Request.Body = io.NopCloser(bytes.NewReader(nil))
		return ""
	}
	c.Request.Body = io.NopCloser(bytes.NewReader(body))
	var payload struct {
		Username string `json:"username"`
	}
	if err := json.Unmarshal(body, &payload); err != nil {
		return ""
	}
	return strings.ToLower(strings.TrimSpace(payload.Username))
}

func itoa(value int) string {
	if value == 0 {
		return "0"
	}
	negative := value < 0
	if negative {
		value = -value
	}
	var digits [12]byte
	i := len(digits)
	for value > 0 {
		i--
		digits[i] = byte('0' + value%10)
		value /= 10
	}
	if negative {
		i--
		digits[i] = '-'
	}
	return string(digits[i:])
}

func RequireProbe(ok func() bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		if ok != nil && !ok() {
			NoteDependencyTimeout()
			c.Header("Retry-After", "1")
			c.AbortWithStatusJSON(http.StatusServiceUnavailable, gin.H{"errorCode": "DEPENDENCY_TIMEOUT"})
			return
		}
		c.Next()
	}
}
