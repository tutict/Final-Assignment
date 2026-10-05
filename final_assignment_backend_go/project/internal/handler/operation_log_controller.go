package handler

import (
	"net/http"
	"net/url"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
)

type OperationLogController struct {
	Service OperationLogService
}

// RegisterRoutes 注册 operation log 的所有接口
func (c *OperationLogController) RegisterRoutes(r *gin.RouterGroup) {
	c.mountOperationLogs(r.Group("/api/operationLogs"))
	c.mountOperationLogs(r.Group("/api/logs/operation"))
}

func (c *OperationLogController) mountOperationLogs(api *gin.RouterGroup) {
	api.POST("", c.createOperationLog)
	api.GET("", c.getAllOperationLogs)
	api.GET("/timeRange", c.getOperationLogsByTimeRange)
	api.GET("/search/time-range", c.getOperationLogsByTimeRange)
	api.GET("/userId/:userId", c.getOperationLogsByUserId)
	api.GET("/search/user/:userId", c.getOperationLogsByUserId)
	api.GET("/result/:result", c.getOperationLogsByResult)
	api.GET("/search/result", c.getOperationLogsByResult)
	api.GET("/search/module", c.searchOperationLogsByModule)
	api.GET("/search/type", c.searchOperationLogsByType)
	api.GET("/search/username", c.searchOperationLogsByUsername)
	api.GET("/search/request-url", c.searchOperationLogsByRequestURL)
	api.GET("/search/request-method", c.searchOperationLogsByRequestMethod)
	api.GET("/autocomplete/user-ids/me", c.getUserIdAutocompleteSuggestions)
	api.GET("/autocomplete/operation-results/me", c.getOperationResultAutocompleteSuggestions)
	api.GET("/:logId", c.getOperationLog)
	api.PUT("/:logId", c.updateOperationLog)
	api.DELETE("/:logId", c.deleteOperationLog)
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

	updated.LogID = id
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
	startTime, endTime, err := queryTimeWindow(ctx)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid time format"})
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
	if result == "" {
		result = firstQuery(ctx, "operationResult", "result")
	}
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

func (c *OperationLogController) searchOperationLogsByModule(ctx *gin.Context) {
	query := ctx.Query("module")
	c.searchOperationLogs(ctx, func(item domain.OperationLog) bool {
		return containsFold(item.OperationModule, query)
	})
}

func (c *OperationLogController) searchOperationLogsByType(ctx *gin.Context) {
	query := ctx.Query("type")
	c.searchOperationLogs(ctx, func(item domain.OperationLog) bool {
		return containsFold(item.OperationType, query)
	})
}

func (c *OperationLogController) searchOperationLogsByUsername(ctx *gin.Context) {
	query := ctx.Query("username")
	c.searchOperationLogs(ctx, func(item domain.OperationLog) bool {
		return containsFold(item.Username, query)
	})
}

func (c *OperationLogController) searchOperationLogsByRequestURL(ctx *gin.Context) {
	query := ctx.Query("requestUrl")
	c.searchOperationLogs(ctx, func(item domain.OperationLog) bool {
		return containsFold(item.RequestURL, query)
	})
}

func (c *OperationLogController) searchOperationLogsByRequestMethod(ctx *gin.Context) {
	query := ctx.Query("requestMethod")
	c.searchOperationLogs(ctx, func(item domain.OperationLog) bool {
		return strings.EqualFold(item.RequestMethod, query)
	})
}

func (c *OperationLogController) searchOperationLogs(ctx *gin.Context, match func(domain.OperationLog) bool) {
	logs, err := c.Service.GetAllOperationLogs()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch operation logs"})
		return
	}
	filtered := make([]domain.OperationLog, 0)
	for _, item := range logs {
		if match(item) {
			filtered = append(filtered, item)
		}
	}
	ctx.JSON(http.StatusOK, filtered)
}
