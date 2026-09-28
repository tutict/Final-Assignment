package reliability

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func ShedRequest(method, path string, utilization float64, awaitingConnections, idleConnections int) bool {
	if path == "" || isHealth(path) {
		return false
	}
	verb := strings.ToUpper(method)
	ledger := isLedger(path)
	if ledger && (verb == http.MethodPost || verb == http.MethodPut || verb == http.MethodDelete) {
		return awaitingConnections > 0 || (utilization >= 0.8 && idleConnections <= 0)
	}
	return verb == http.MethodGet && !ledger && utilization >= 0.8
}

func LoadShed(db *gorm.DB, enabled bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		if !enabled || db == nil || c.Request == nil || c.Request.URL == nil {
			c.Next()
			return
		}
		sqlDB, err := db.DB()
		if err != nil || sqlDB == nil {
			c.Next()
			return
		}
		stats := sqlDB.Stats()
		utilization := 0.0
		awaiting := 0
		if stats.MaxOpenConnections > 0 {
			utilization = float64(stats.InUse) / float64(stats.MaxOpenConnections)
			if stats.InUse >= stats.MaxOpenConnections && stats.Idle == 0 {
				awaiting = 1
			}
		}
		if !ShedRequest(c.Request.Method, c.Request.URL.Path, utilization, awaiting, stats.Idle) {
			c.Next()
			return
		}
		NoteLoadShed()
		c.Header("Retry-After", "1")
		c.AbortWithStatusJSON(http.StatusServiceUnavailable, gin.H{
			"errorCode": "LOAD_SHED",
			"message":   "Overloaded",
		})
	}
}

func isLedger(path string) bool {
	value := path
	if !strings.HasPrefix(value, "/") {
		value = "/" + value
	}
	return strings.HasPrefix(value, "/api/payments") ||
		strings.HasPrefix(value, "/api/fines") ||
		strings.HasPrefix(value, "/api/deductions") ||
		strings.HasPrefix(value, "/api/appeals") ||
		strings.HasPrefix(value, "/api/offenses")
}

func isHealth(path string) bool {
	return strings.HasPrefix(path, "/actuator/health") ||
		strings.HasPrefix(path, "/q/health") ||
		strings.HasPrefix(path, "/api/actuator/health")
}
