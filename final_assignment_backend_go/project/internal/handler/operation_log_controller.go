package handler

import (
	"net/http"
	"net/url"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"
)

type OperationLogController struct {
	Service *service.OperationLogService
}

// RegisterRoutes 注册 operation log 的所有接口
func (c *OperationLogController) RegisterRoutes(r *gin.RouterGroup) {
	api := r.Group("/api/operationLogs")

	api.POST("", c.createOperationLog)
	api.GET("/:logId", c.getOperationLog)
	api.GET("", c.getAllOperationLogs)
	api.PUT("/:logId", c.updateOperationLog)
	api.DELETE("/:logId", c.deleteOperationLog)
	api.GET("/timeRange", c.getOperationLogsByTimeRange)
	api.GET("/userId/:userId", c.getOperationLogsByUserId)
	api.GET("/result/:result", c.getOperationLogsByResult)
	api.GET("/autocomplete/user-ids/me", c.getUserIdAutocompleteSuggestions)
	api.GET("/autocomplete/operation-results/me", c.getOperationResultAutocompleteSuggestions)
}

// POST /api/operationLogs
func (c *OperationLogController) createOperationLog(ctx *gin.Context) {
	var logEntry domain.OperationLog
	idempotencyKey := ctx.Query("idempotencyKey")

	if err := ctx.ShouldBindJSON(&logEntry); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	if err := c.Service.CheckAndInsertIdempotency(idempotencyKey, &logEntry, "create"); err != nil {
		ctx.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	ctx.Status(http.StatusCreated)
}

// GET /api/operationLogs/:logId
func (c *OperationLogController) getOperationLog(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("logId"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid log ID"})
		return
	}

	logEntry, err := c.Service.GetOperationLog(id)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "operation log not found"})
		return
	}

	ctx.JSON(http.StatusOK, logEntry)
}

// GET /api/operationLogs
func (c *OperationLogController) getAllOperationLogs(ctx *gin.Context) {
	logs, err := c.Service.GetAllOperationLogs()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch operation logs"})
		return
	}
	ctx.JSON(http.StatusOK, logs)
}

// PUT /api/operationLogs/:logId
func (c *OperationLogController) updateOperationLog(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("logId"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid log ID"})
		return
	}

	var updated domain.OperationLog
	idempotencyKey := ctx.Query("idempotencyKey")

	if err := ctx.ShouldBindJSON(&updated); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	existing, err := c.Service.GetOperationLog(id)
	if err != nil || existing == nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "operation log not found"})
		return
	}

	updated.LogID = uint(id)
	if err := c.Service.CheckAndInsertIdempotency(idempotencyKey, &updated, "update"); err != nil {
		ctx.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, updated)
}

// DELETE /api/operationLogs/:logId
func (c *OperationLogController) deleteOperationLog(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("logId"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid log ID"})
		return
	}

	if err := c.Service.DeleteOperationLog(id); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete operation log"})
		return
	}

	ctx.Status(http.StatusNoContent)
}

// GET /api/operationLogs/timeRange
func (c *OperationLogController) getOperationLogsByTimeRange(ctx *gin.Context) {
	startStr := ctx.DefaultQuery("startTime", "1970-01-01")
	endStr := ctx.DefaultQuery("endTime", "2100-01-01")

	startTime, err := time.Parse("2006-01-02", startStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid startTime format"})
		return
	}
	endTime, err := time.Parse("2006-01-02", endStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid endTime format"})
		return
	}

	logs, err := c.Service.GetOperationLogsByTimeRange(startTime, endTime)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "query failed"})
		return
	}
	ctx.JSON(http.StatusOK, logs)
}

// GET /api/operationLogs/userId/:userId
func (c *OperationLogController) getOperationLogsByUserId(ctx *gin.Context) {
	userId := ctx.Param("userId")
	logs, err := c.Service.GetOperationLogsByUserId(userId)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "query failed"})
		return
	}
	ctx.JSON(http.StatusOK, logs)
}

// GET /api/operationLogs/result/:result
func (c *OperationLogController) getOperationLogsByResult(ctx *gin.Context) {
	result := ctx.Param("result")
	logs, err := c.Service.GetOperationLogsByResult(result)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "query failed"})
		return
	}
	ctx.JSON(http.StatusOK, logs)
}

// GET /api/operationLogs/autocomplete/user-ids/me
func (c *OperationLogController) getUserIdAutocompleteSuggestions(ctx *gin.Context) {
	prefix := ctx.Query("prefix")
	decoded, err := url.QueryUnescape(prefix)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid prefix"})
		return
	}

	suggestions, err := c.Service.GetUserIdsByPrefixGlobally(decoded)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "query failed"})
		return
	}

	if len(suggestions) == 0 {
		ctx.Status(http.StatusNoContent)
		return
	}

	ctx.JSON(http.StatusOK, suggestions)
}

// GET /api/operationLogs/autocomplete/operation-results/me
func (c *OperationLogController) getOperationResultAutocompleteSuggestions(ctx *gin.Context) {
	prefix := ctx.Query("prefix")
	decoded, err := url.QueryUnescape(prefix)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid prefix"})
		return
	}

	suggestions, err := c.Service.GetOperationResultsByPrefixGlobally(decoded)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "query failed"})
		return
	}

	if len(suggestions) == 0 {
		ctx.Status(http.StatusNoContent)
		return
	}

	ctx.JSON(http.StatusOK, suggestions)
}
