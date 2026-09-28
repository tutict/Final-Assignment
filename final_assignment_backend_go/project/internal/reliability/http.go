package reliability

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"sync/atomic"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

var (
	loadShedTotal       atomic.Int64
	aiFallback          atomic.Int64
	dependencyTimeout   atomic.Int64
	idempotencyConflict atomic.Int64
	kafkaPublishFailed  atomic.Int64
	http2xx             atomic.Int64
	http4xx             atomic.Int64
	http5xx             atomic.Int64
)

func Health(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, cancel := context.WithTimeout(c.Request.Context(), time.Second)
		defer cancel()
		sqlDB, err := db.DB()
		if err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"status": "DOWN"})
			return
		}
		if err = sqlDB.PingContext(ctx); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"status": "DOWN"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "UP"})
	}
}

func Liveness(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "UP"})
}

func Prometheus(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		roles, _ := c.Get("normalizedRoles")
		if !hasAdmin(roles) {
			c.AbortWithStatus(http.StatusForbidden)
			return
		}
		c.Header("Content-Type", "text/plain; version=0.0.4")
		_, _ = fmt.Fprintf(c.Writer, ""+
			"load_shed_total %d\n"+
			"idempotency_conflict_total %d\n"+
			"dependency_timeout_total %d\n"+
			"kafka_publish_failed_total %d\n"+
			"ai_fallback_total %d\n"+
			"backup_last_success_timestamp %d\n"+
			"db_pool_wait_count %d\n"+
			"http_responses_2xx_total %d\n"+
			"http_responses_4xx_total %d\n"+
			"http_responses_5xx_total %d\n",
			loadShedTotal.Load(),
			idempotencyConflict.Load(),
			dependencyTimeout.Load(),
			kafkaPublishFailed.Load(),
			aiFallback.Load(),
			backupSuccessEpoch(db),
			poolWaitCount(db),
			http2xx.Load(),
			http4xx.Load(),
			http5xx.Load(),
		)
	}
}

func NoteLoadShed()            { loadShedTotal.Add(1) }
func NoteAIFallback()          { aiFallback.Add(1) }
func NoteDependencyTimeout()   { dependencyTimeout.Add(1) }
func NoteIdempotencyConflict() { idempotencyConflict.Add(1) }
func NoteKafkaPublishFailed()  { kafkaPublishFailed.Add(1) }

func KafkaPublishFailedCount() int64 { return kafkaPublishFailed.Load() }

func NoteHTTPStatus(status int) {
	switch {
	case status >= 200 && status < 300:
		http2xx.Add(1)
	case status >= 400 && status < 500:
		http4xx.Add(1)
	case status >= 500 && status < 600:
		http5xx.Add(1)
	}
}

func ObserveResponses() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
		NoteHTTPStatus(c.Writer.Status())
	}
}

func resetMetrics() {
	loadShedTotal.Store(0)
	aiFallback.Store(0)
	dependencyTimeout.Store(0)
	idempotencyConflict.Store(0)
	kafkaPublishFailed.Store(0)
	http2xx.Store(0)
	http4xx.Store(0)
	http5xx.Store(0)
}

func backupSuccessEpoch(db *gorm.DB) int64 {
	if db == nil {
		return 0
	}
	var epoch sql.NullInt64
	err := db.Raw("SELECT UNIX_TIMESTAMP(MAX(backup_time)) FROM sys_backup_restore WHERE status = 'Success' AND deleted_at IS NULL").Row().Scan(&epoch)
	if err != nil || !epoch.Valid {
		return 0
	}
	return epoch.Int64
}

func poolWaitCount(db *gorm.DB) int64 {
	if db == nil {
		return 0
	}
	sqlDB, err := db.DB()
	if err != nil || sqlDB == nil {
		return 0
	}
	return sqlDB.Stats().WaitCount
}

func hasAdmin(value any) bool {
	roles, ok := value.([]string)
	if !ok {
		return false
	}
	for _, role := range roles {
		if role == "ADMIN" || role == "SUPER_ADMIN" {
			return true
		}
	}
	return false
}
func LedgerReconcile(reconcile func() (int, error)) gin.HandlerFunc {
	return func(c *gin.Context) {
		roles, _ := c.Get("normalizedRoles")
		if !hasAdmin(roles) {
			c.AbortWithStatus(http.StatusForbidden)
			return
		}
		updated, err := reconcile()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"errorCode": "RECONCILE_FAILED"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"updated": updated})
	}
}

