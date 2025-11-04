package handler

import (
	"log"
	"net/http"
	"net/url"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/service"

	"final_assignment_backend_go/project/internal/domain"
)

// LoginLogController 负责路由与请求处理
type LoginLogController struct {
	service *service.LoginLogService
}

// NewLoginLogController 创建控制器实例
func NewLoginLogController(s *service.LoginLogService) *LoginLogController {
	return &LoginLogController{service: s}
}

// RegisterRoutes 注册路由
func (c *LoginLogController) RegisterRoutes(r *gin.Engine) {
	group := r.Group("/api/loginLogs")
	{
		group.POST("", c.CreateLoginLog)
		group.GET("", c.GetAllLoginLogs)
		group.GET("/:logId", c.GetLoginLogByID)
		group.PUT("/:logId", c.UpdateLoginLog)
		group.DELETE("/:logId", c.DeleteLoginLog)

		group.GET("/timeRange", c.GetLoginLogsByTimeRange)
		group.GET("/username/:username", c.GetLoginLogsByUsername)
		group.GET("/loginResult/:loginResult", c.GetLoginLogsByLoginResult)

		group.GET("/autocomplete/usernames/me", c.GetUsernameAutocomplete)
		group.GET("/autocomplete/login-results/me", c.GetLoginResultAutocomplete)
	}
}

// CreateLoginLog POST /api/loginLogs
func (c *LoginLogController) CreateLoginLog(ctx *gin.Context) {
	var logEntry domain.LoginLog
	idempotencyKey := ctx.Query("idempotencyKey")

	if err := ctx.ShouldBindJSON(&logEntry); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	if err := c.service.CheckAndInsertIdempotency(idempotencyKey, &logEntry, "create"); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ctx.Status(http.StatusCreated)
}

// GetLoginLogByID GET /api/loginLogs/:logId
func (c *LoginLogController) GetLoginLogByID(ctx *gin.Context) {
	id := ctx.Param("logId")
	logEntry, err := c.service.GetLoginLogByID(id)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	ctx.JSON(http.StatusOK, logEntry)
}

// GetAllLoginLogs GET /api/loginLogs
func (c *LoginLogController) GetAllLoginLogs(ctx *gin.Context) {
	logs, err := c.service.GetAllLoginLogs()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, logs)
}

// UpdateLoginLog PUT /api/loginLogs/:logId
func (c *LoginLogController) UpdateLoginLog(ctx *gin.Context) {
	id := ctx.Param("logId")
	idempotencyKey := ctx.Query("idempotencyKey")
	var updated domain.LoginLog

	if err := ctx.ShouldBindJSON(&updated); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid input"})
		return
	}

	updated.ID = id
	if err := c.service.CheckAndInsertIdempotency(idempotencyKey, &updated, "update"); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, updated)
}

// DeleteLoginLog DELETE /api/loginLogs/:logId
func (c *LoginLogController) DeleteLoginLog(ctx *gin.Context) {
	id := ctx.Param("logId")
	if err := c.service.DeleteLoginLog(id); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.Status(http.StatusNoContent)
}

// GetLoginLogsByTimeRange GET /api/loginLogs/timeRange?start=2020-01-01&end=2025-01-01
func (c *LoginLogController) GetLoginLogsByTimeRange(ctx *gin.Context) {
	startStr := ctx.DefaultQuery("start", "1970-01-01")
	endStr := ctx.DefaultQuery("end", "2100-01-01")

	start, _ := time.Parse("2006-01-02", startStr)
	end, _ := time.Parse("2006-01-02", endStr)

	logs, err := c.service.GetLoginLogsByTimeRange(start, end)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, logs)
}

// GetLoginLogsByUsername GET /api/loginLogs/username/:username
func (c *LoginLogController) GetLoginLogsByUsername(ctx *gin.Context) {
	username := ctx.Param("username")
	logs, err := c.service.GetLoginLogsByUsername(username)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, logs)
}

// GetLoginLogsByLoginResult GET /api/loginLogs/loginResult/:loginResult
func (c *LoginLogController) GetLoginLogsByLoginResult(ctx *gin.Context) {
	result := ctx.Param("loginResult")
	logs, err := c.service.GetLoginLogsByLoginResult(result)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, logs)
}

// GetUsernameAutocomplete GET /api/loginLogs/autocomplete/usernames/me?prefix=adm
func (c *LoginLogController) GetUsernameAutocomplete(ctx *gin.Context) {
	prefix := ctx.Query("prefix")
	decoded, _ := url.QueryUnescape(prefix)
	log.Printf("Fetching username suggestions for prefix: %s (decoded: %s)", prefix, decoded)

	suggestions := c.service.GetUsernamesByPrefixGlobally(decoded)
	ctx.JSON(http.StatusOK, suggestions)
}

// GetLoginResultAutocomplete GET /api/loginLogs/autocomplete/login-results/me?prefix=succ
func (c *LoginLogController) GetLoginResultAutocomplete(ctx *gin.Context) {
	prefix := ctx.Query("prefix")
	decoded, _ := url.QueryUnescape(prefix)
	log.Printf("Fetching login result suggestions for prefix: %s (decoded: %s)", prefix, decoded)

	suggestions := c.service.GetLoginResultsByPrefixGlobally(decoded)
	ctx.JSON(http.StatusOK, suggestions)
}
