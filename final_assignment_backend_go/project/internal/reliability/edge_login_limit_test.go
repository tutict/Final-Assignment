package reliability

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
)

func TestLoginRateLimitAccountLockIgnoresForwardedHeader(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.POST("/api/auth/login", LoginRateLimit(), func(c *gin.Context) {
		c.Status(http.StatusOK)
	})

	for i := 0; i < loginAccountLimit; i++ {
		status := postLogin(router, `{"username":"ce@ce.com","password":"x"}`, "203.0.113.9")
		if status != http.StatusOK {
			t.Fatalf("attempt %d status=%d", i+1, status)
		}
	}
	req := httptest.NewRequest(http.MethodPost, "/api/auth/login", bytes.NewBufferString(`{"username":"ce@ce.com","password":"x"}`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Forwarded-For", "198.51.100.20")
	req.RemoteAddr = "203.0.113.9:4321"
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	if rec.Code != http.StatusTooManyRequests {
		t.Fatalf("expected 429, got %d body=%s", rec.Code, rec.Body.String())
	}
	if rec.Header().Get("Retry-After") != "120" {
		t.Fatalf("Retry-After=%q", rec.Header().Get("Retry-After"))
	}
	other := postLogin(router, `{"username":"other@ce.com","password":"x"}`, "203.0.113.9")
	if other != http.StatusOK {
		t.Fatalf("different account should still pass under the IP cap, got %d", other)
	}
	_ = time.Minute
}

func postLogin(router *gin.Engine, body string, ip string) int {
	req := httptest.NewRequest(http.MethodPost, "/api/auth/login", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Forwarded-For", "198.51.100.8")
	req.RemoteAddr = ip + ":1000"
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	return rec.Code
}
