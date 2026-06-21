package middleware

import (
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
)

// SlowQueryConfig holds configuration for slow query logging
type SlowQueryConfig struct {
	Threshold time.Duration
	LogFunc   func(method, path string, duration time.Duration)
}

// DefaultSlowQueryConfig returns default configuration
func DefaultSlowQueryConfig() *SlowQueryConfig {
	return &SlowQueryConfig{
		Threshold: 500 * time.Millisecond,
		LogFunc: func(method, path string, duration time.Duration) {
			fmt.Printf("[SLOW QUERY] %s %s took %v\n", method, path, duration)
		},
	}
}

// SlowQueryMiddleware creates a middleware for logging slow HTTP requests
func SlowQueryMiddleware(config *SlowQueryConfig) gin.HandlerFunc {
	if config == nil {
		config = DefaultSlowQueryConfig()
	}

	return func(c *gin.Context) {
		start := time.Now()

		// Process request
		c.Next()

		// Calculate duration
		duration := time.Since(start)

		// Log if slow
		if duration > config.Threshold {
			config.LogFunc(c.Request.Method, c.Request.URL.Path, duration)
		}
	}
}

// SlowQueryMiddlewareWithThreshold creates middleware with custom threshold
func SlowQueryMiddlewareWithThreshold(threshold time.Duration) gin.HandlerFunc {
	return SlowQueryMiddleware(&SlowQueryConfig{
		Threshold: threshold,
		LogFunc: func(method, path string, duration time.Duration) {
			fmt.Printf("[SLOW QUERY] %s %s took %v (threshold: %v)\n",
				method, path, duration, threshold)
		},
	})
}
