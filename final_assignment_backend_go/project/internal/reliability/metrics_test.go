package reliability

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestShedRequestMatchesLedgerPolicy(t *testing.T) {
	if !ShedRequest(http.MethodGet, "/api/auth/me", 0.8, 0, 1) {
		t.Fatal("non-ledger GET should shed at 80 percent")
	}
	if ShedRequest(http.MethodGet, "/api/payments/1", 0.9, 0, 0) {
		t.Fatal("ledger GET should stay available")
	}
	if !ShedRequest(http.MethodPost, "/api/payments", 0.9, 0, 0) {
		t.Fatal("ledger write should shed when the pool has no idle connection")
	}
	if !ShedRequest(http.MethodPost, "/api/payments", 0.1, 1, 0) {
		t.Fatal("ledger write should shed when a connection cannot be acquired")
	}
	if ShedRequest(http.MethodGet, "/actuator/health", 1, 4, 0) {
		t.Fatal("health must not be shed")
	}
}

func TestPrometheusReportsIncrementedCounters(t *testing.T) {
	resetMetrics()
	t.Cleanup(resetMetrics)
	NoteLoadShed()
	NoteDependencyTimeout()
	NoteIdempotencyConflict()
	NoteKafkaPublishFailed()
	NoteAIFallback()
	NoteHTTPStatus(http.StatusCreated)
	NoteHTTPStatus(http.StatusConflict)
	NoteHTTPStatus(http.StatusServiceUnavailable)

	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("normalizedRoles", []string{"ADMIN"})
		c.Next()
	})
	router.GET("/actuator/prometheus", Prometheus(nil))
	req := httptest.NewRequest(http.MethodGet, "/actuator/prometheus", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
	body := rec.Body.String()
	for _, line := range []string{
		"load_shed_total 1",
		"idempotency_conflict_total 1",
		"dependency_timeout_total 1",
		"kafka_publish_failed_total 1",
		"ai_fallback_total 1",
		"backup_last_success_timestamp 0",
		"db_pool_wait_count 0",
		"http_responses_2xx_total 1",
		"http_responses_4xx_total 1",
		"http_responses_5xx_total 1",
	} {
		if !strings.Contains(body, line) {
			t.Fatalf("missing %q in %s", line, body)
		}
	}
}

func TestPrometheusRequiresAdmin(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.GET("/actuator/prometheus", Prometheus(nil))
	req := httptest.NewRequest(http.MethodGet, "/actuator/prometheus", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("status=%d", rec.Code)
	}
}

func TestRequireProbeCountsDependencyTimeout(t *testing.T) {
	resetMetrics()
	t.Cleanup(resetMetrics)
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.GET("/api/payments", RequireProbe(func() bool { return false }), func(c *gin.Context) {
		c.Status(http.StatusOK)
	})
	req := httptest.NewRequest(http.MethodGet, "/api/payments", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status=%d", rec.Code)
	}
	if rec.Header().Get("Retry-After") != "1" {
		t.Fatalf("Retry-After=%q", rec.Header().Get("Retry-After"))
	}
	if dependencyTimeout.Load() != 1 {
		t.Fatalf("dependency_timeout=%d", dependencyTimeout.Load())
	}
}
