package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
)

func TestSlowQueryMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name          string
		threshold     time.Duration
		handlerDelay  time.Duration
		expectLogged  bool
	}{
		{
			name:         "fast request - not logged",
			threshold:    500 * time.Millisecond,
			handlerDelay: 100 * time.Millisecond,
			expectLogged: false,
		},
		{
			name:         "slow request - logged",
			threshold:    500 * time.Millisecond,
			handlerDelay: 600 * time.Millisecond,
			expectLogged: true,
		},
		{
			name:         "just over threshold",
			threshold:    500 * time.Millisecond,
			handlerDelay: 520 * time.Millisecond,
			expectLogged: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			logged := false
			config := &SlowQueryConfig{
				Threshold: tt.threshold,
				LogFunc: func(method, path string, duration time.Duration) {
					logged = true
					if duration < tt.threshold {
						t.Errorf("LogFunc called for duration %v, threshold %v", duration, tt.threshold)
					}
				},
			}

			router := gin.New()
			router.Use(SlowQueryMiddleware(config))
			router.GET("/test", func(c *gin.Context) {
				time.Sleep(tt.handlerDelay)
				c.String(http.StatusOK, "ok")
			})

			w := httptest.NewRecorder()
			req := httptest.NewRequest("GET", "/test", nil)
			router.ServeHTTP(w, req)

			if logged != tt.expectLogged {
				t.Errorf("logged = %v, want %v", logged, tt.expectLogged)
			}

			if w.Code != http.StatusOK {
				t.Errorf("Status = %d, want %d", w.Code, http.StatusOK)
			}
		})
	}
}

func TestSlowQueryMiddlewareWithThreshold(t *testing.T) {
	gin.SetMode(gin.TestMode)

	logged := false

	router := gin.New()
	router.Use(SlowQueryMiddlewareWithThreshold(200 * time.Millisecond))
	router.GET("/test", func(c *gin.Context) {
		time.Sleep(250 * time.Millisecond)
		logged = true
		c.String(http.StatusOK, "ok")
	})

	w := httptest.NewRecorder()
	req := httptest.NewRequest("GET", "/test", nil)
	router.ServeHTTP(w, req)

	if !logged {
		t.Error("Handler should have been called")
	}
}

func TestDefaultSlowQueryConfig(t *testing.T) {
	config := DefaultSlowQueryConfig()

	if config.Threshold != 500*time.Millisecond {
		t.Errorf("Default threshold = %v, want 500ms", config.Threshold)
	}

	if config.LogFunc == nil {
		t.Error("Default LogFunc should not be nil")
	}
}

func TestSlowQueryMiddleware_NilConfig(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	router.Use(SlowQueryMiddleware(nil)) // Should use default config
	router.GET("/test", func(c *gin.Context) {
		c.String(http.StatusOK, "ok")
	})

	w := httptest.NewRecorder()
	req := httptest.NewRequest("GET", "/test", nil)
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Status = %d, want %d", w.Code, http.StatusOK)
	}
}

func TestSlowQueryMiddleware_MultipleRequests(t *testing.T) {
	gin.SetMode(gin.TestMode)

	logCount := 0
	config := &SlowQueryConfig{
		Threshold: 100 * time.Millisecond,
		LogFunc: func(method, path string, duration time.Duration) {
			logCount++
		},
	}

	router := gin.New()
	router.Use(SlowQueryMiddleware(config))
	router.GET("/fast", func(c *gin.Context) {
		c.String(http.StatusOK, "fast")
	})
	router.GET("/slow", func(c *gin.Context) {
		time.Sleep(150 * time.Millisecond)
		c.String(http.StatusOK, "slow")
	})

	// Fast request
	w := httptest.NewRecorder()
	req := httptest.NewRequest("GET", "/fast", nil)
	router.ServeHTTP(w, req)

	// Slow request
	w = httptest.NewRecorder()
	req = httptest.NewRequest("GET", "/slow", nil)
	router.ServeHTTP(w, req)

	// Another slow request
	w = httptest.NewRecorder()
	req = httptest.NewRequest("GET", "/slow", nil)
	router.ServeHTTP(w, req)

	// Should have logged 2 slow requests
	if logCount != 2 {
		t.Errorf("logCount = %d, want 2", logCount)
	}
}
