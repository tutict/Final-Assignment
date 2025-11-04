package handler

import (
	"log"
	"net/http"
	"net/url"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"
)

// SystemLogsController 负责处理系统日志相关请求
type SystemLogsController struct {
	SystemLogsService *service.SystemLogsService
}

// NewSystemLogsController 创建新的控制器实例
func NewSystemLogsController(svc *service.SystemLogsService) *SystemLogsController {
	return &SystemLogsController{SystemLogsService: svc}
}

// RegisterRoutes 注册路由
func (ctrl *SystemLogsController) RegisterRoutes(r *gin.Engine) {
	group := r.Group("/api/systemLogs")

	group.POST("", ctrl.CreateSystemLog)
	group.GET("/:logId", ctrl.GetSystemLogByID)
	group.GET("", ctrl.GetAllSystemLogs)
	group.GET("/type/:logType", ctrl.GetSystemLogsByType)
	group.GET("/timeRange", ctrl.GetSystemLogsByTimeRange)
	group.GET("/operationUser/:operationUser", ctrl.GetSystemLogsByOperationUser)
	group.PUT("/:logId", ctrl.UpdateSystemLog)
	group.DELETE("/:logId", ctrl.DeleteSystemLog)
	group.GET("/autocomplete/log-types/me", ctrl.GetLogTypeAutocompleteSuggestionsGlobally)
	group.GET("/autocomplete/operation-users/me", ctrl.GetOperationUserAutocompleteSuggestionsGlobally)
}

// CreateSystemLog 创建系统日志记录
func (ctrl *SystemLogsController) CreateSystemLog(c *gin.Context) {
	idempotencyKey := c.Query("idempotencyKey")
	if idempotencyKey == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "idempotencyKey is required"})
		return
	}

	var logEntry domain.SystemLogs
	if err := c.ShouldBindJSON(&logEntry); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := ctrl.SystemLogsService.CheckAndInsertIdempotency(idempotencyKey, &logEntry, "create")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusCreated)
}

// GetSystemLogByID 根据ID获取系统日志
func (ctrl *SystemLogsController) GetSystemLogByID(c *gin.Context) {
	logID := c.Param("logId")
	systemLog, err := ctrl.SystemLogsService.GetSystemLogByID(logID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "log not found"})
		return
	}
	c.JSON(http.StatusOK, systemLog)
}

// GetAllSystemLogs 获取所有系统日志
func (ctrl *SystemLogsController) GetAllSystemLogs(c *gin.Context) {
	logs, err := ctrl.SystemLogsService.GetAllSystemLogs()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, logs)
}

// GetSystemLogsByType 根据日志类型获取系统日志
func (ctrl *SystemLogsController) GetSystemLogsByType(c *gin.Context) {
	logType := c.Param("logType")
	logs, err := ctrl.SystemLogsService.GetSystemLogsByType(logType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, logs)
}

// GetSystemLogsByTimeRange 根据时间范围获取系统日志
func (ctrl *SystemLogsController) GetSystemLogsByTimeRange(c *gin.Context) {
	startStr := c.Query("startTime")
	endStr := c.Query("endTime")

	start, err1 := time.Parse("2006-01-02", startStr)
	end, err2 := time.Parse("2006-01-02", endStr)
	if err1 != nil || err2 != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid date format, expected yyyy-MM-dd"})
		return
	}

	logs, err := ctrl.SystemLogsService.GetSystemLogsByTimeRange(start, end)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, logs)
}

// GetSystemLogsByOperationUser 根据操作用户获取系统日志
func (ctrl *SystemLogsController) GetSystemLogsByOperationUser(c *gin.Context) {
	user := c.Param("operationUser")
	logs, err := ctrl.SystemLogsService.GetSystemLogsByOperationUser(user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, logs)
}

// UpdateSystemLog 更新系统日志记录
func (ctrl *SystemLogsController) UpdateSystemLog(c *gin.Context) {
	logID := c.Param("logId")
	idempotencyKey := c.Query("idempotencyKey")

	var updated domain.SystemLogs
	if err := c.ShouldBindJSON(&updated); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	existing, err := ctrl.SystemLogsService.GetSystemLogByID(logID)
	if err != nil || existing == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "log not found"})
		return
	}

	updated.LogID = existing.LogID
	err = ctrl.SystemLogsService.CheckAndInsertIdempotency(idempotencyKey, &updated, "update")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, updated)
}

// DeleteSystemLog 删除系统日志
func (ctrl *SystemLogsController) DeleteSystemLog(c *gin.Context) {
	logID := c.Param("logId")
	err := ctrl.SystemLogsService.DeleteSystemLog(logID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

// GetLogTypeAutocompleteSuggestionsGlobally 日志类型自动补全
func (ctrl *SystemLogsController) GetLogTypeAutocompleteSuggestionsGlobally(c *gin.Context) {
	prefix := c.Query("prefix")
	decoded, _ := url.QueryUnescape(prefix)

	suggestions, err := ctrl.SystemLogsService.GetLogTypesByPrefixGlobally(decoded)
	if err != nil {
		log.Printf("Error fetching log type suggestions: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if len(suggestions) == 0 {
		c.Status(http.StatusNoContent)
		return
	}

	c.JSON(http.StatusOK, suggestions)
}

// GetOperationUserAutocompleteSuggestionsGlobally 操作用户自动补全
func (ctrl *SystemLogsController) GetOperationUserAutocompleteSuggestionsGlobally(c *gin.Context) {
	prefix := c.Query("prefix")
	decoded, _ := url.QueryUnescape(prefix)

	suggestions, err := ctrl.SystemLogsService.GetOperationUsersByPrefixGlobally(decoded)
	if err != nil {
		log.Printf("Error fetching user suggestions: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if len(suggestions) == 0 {
		c.Status(http.StatusNoContent)
		return
	}

	c.JSON(http.StatusOK, suggestions)
}
