package handler

import (
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/reliability"
)


func idempotencyKey(c *gin.Context) string {
	key := strings.TrimSpace(c.GetHeader("Idempotency-Key"))
	if key == "" {
		key = strings.TrimSpace(c.Query("idempotencyKey"))
	}
	return key
}

func requireIdempotencyKey(c *gin.Context) (string, bool) {
	key := strings.TrimSpace(c.GetHeader("Idempotency-Key"))
	if key == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"errorCode": "MISSING_HEADER",
			"message":   "Missing required header: Idempotency-Key",
		})
		return "", false
	}
	return key, true
}

func writeLedgerError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, reliability.ErrReplay):
		c.JSON(http.StatusAlreadyReported, gin.H{"success": true})
	case errors.Is(err, reliability.ErrKeyRequired):
		c.JSON(http.StatusBadRequest, gin.H{
			"errorCode": "MISSING_HEADER",
			"message":   "Missing required header: Idempotency-Key",
		})
	case errors.Is(err, reliability.ErrConflict):
		reliability.NoteIdempotencyConflict()
		c.JSON(http.StatusConflict, gin.H{"errorCode": "IDEMPOTENCY_CONFLICT", "message": err.Error()})
	case errors.Is(err, reliability.ErrInProgress):
		c.Header("Retry-After", "1")
		c.JSON(http.StatusConflict, gin.H{"errorCode": "IDEMPOTENCY_IN_PROGRESS", "message": err.Error()})
	default:
		if writeConnectionWait(c, err) {
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"errorCode": "INTERNAL_ERROR", "message": err.Error()})
	}
}

func writeConnectionWait(c *gin.Context, err error) bool {
	if !reliability.ConnectionWait(err) {
		return false
	}
	reliability.NoteDependencyTimeout()
	c.Header("Retry-After", "1")
	c.JSON(http.StatusServiceUnavailable, gin.H{
		"errorCode": "DEPENDENCY_TIMEOUT",
		"message":   "Database connection wait exceeded 200ms",
	})
	return true
}

func writeBusinessOrLedgerError(c *gin.Context, err error) {
	if err == nil {
		return
	}
	msg := err.Error()
	if strings.Contains(msg, "请") || strings.Contains(msg, "未找到") || strings.Contains(msg, "不唯一") {
		c.JSON(http.StatusBadRequest, gin.H{
			"success":   false,
			"errorCode": "INVALID_ARGUMENT",
			"message":   msg,
		})
		return
	}
	writeLedgerError(c, err)
}
