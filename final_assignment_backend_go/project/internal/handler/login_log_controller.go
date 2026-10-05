package handler

import (
	"log"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
)

// LoginLogController 负责路由与请求处理
type LoginLogController struct {
	service LoginLogService
}

// NewLoginLogController 创建控制器实例
func NewLoginLogController(s LoginLogService) *LoginLogController {
	return &LoginLogController{service: s}
}

// RegisterRoutes 注册路由
func (c *LoginLogController) RegisterRoutes(r *gin.Engine) {
	c.mountLoginLogs(r.Group("/api/loginLogs"))
	c.mountLoginLogs(r.Group("/api/logs/login"))
}

func (c *LoginLogController) mountLoginLogs(group *gin.RouterGroup) {
	group.POST("", c.CreateLoginLog)
	group.GET("", c.GetAllLoginLogs)
	group.GET("/timeRange", c.GetLoginLogsByTimeRange)
	group.GET("/search/time-range", c.GetLoginLogsByTimeRange)
	group.GET("/username/:username", c.GetLoginLogsByUsername)
	group.GET("/search/username", c.GetLoginLogsByUsername)
	group.GET("/loginResult/:loginResult", c.GetLoginLogsByLoginResult)
	group.GET("/search/result", c.GetLoginLogsByLoginResult)
	group.GET("/search/ip", c.SearchLoginLogsByIP)
	group.GET("/search/location", c.SearchLoginLogsByLocation)
	group.GET("/search/device-type", c.SearchLoginLogsByDeviceType)
	group.GET("/search/browser-type", c.SearchLoginLogsByBrowserType)
	group.GET("/search/logout-time-range", c.SearchLoginLogsByLogoutTime)
	group.GET("/autocomplete/usernames/me", c.GetUsernameAutocomplete)
	group.GET("/autocomplete/login-results/me", c.GetLoginResultAutocomplete)
	group.GET("/:logId", c.GetLoginLogByID)
	group.PUT("/:logId", c.UpdateLoginLog)
	group.DELETE("/:logId", c.DeleteLoginLog)
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

	parsed, err := strconv.Atoi(id)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid log id"})
		return
	}
	updated.LogID = parsed
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
	start, end, err := queryTimeWindow(ctx)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid time format"})
		return
	}
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
	if username == "" {
		username = ctx.Query("username")
	}
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
	if result == "" {
		result = ctx.Query("result")
	}
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

func (c *LoginLogController) SearchLoginLogsByIP(ctx *gin.Context) {
	query := ctx.Query("ip")
	c.searchLoginLogs(ctx, func(item domain.LoginLog) bool {
		return containsFold(item.LoginIP, query)
	})
}

func (c *LoginLogController) SearchLoginLogsByLocation(ctx *gin.Context) {
	query := ctx.Query("loginLocation")
	c.searchLoginLogs(ctx, func(item domain.LoginLog) bool {
		return containsFold(item.LoginLocation, query)
	})
}

func (c *LoginLogController) SearchLoginLogsByDeviceType(ctx *gin.Context) {
	query := ctx.Query("deviceType")
	c.searchLoginLogs(ctx, func(item domain.LoginLog) bool {
		return containsFold(item.DeviceType, query)
	})
}

func (c *LoginLogController) SearchLoginLogsByBrowserType(ctx *gin.Context) {
	query := ctx.Query("browserType")
	c.searchLoginLogs(ctx, func(item domain.LoginLog) bool {
		return containsFold(item.BrowserType, query)
	})
}

func (c *LoginLogController) SearchLoginLogsByLogoutTime(ctx *gin.Context) {
	start, end, err := queryTimeWindow(ctx)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid time format"})
		return
	}
	c.searchLoginLogs(ctx, func(item domain.LoginLog) bool {
		return item.LogoutTime != nil && !item.LogoutTime.Before(start) && !item.LogoutTime.After(end)
	})
}

func (c *LoginLogController) searchLoginLogs(ctx *gin.Context, match func(domain.LoginLog) bool) {
	logs, err := c.service.GetAllLoginLogs()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	filtered := make([]domain.LoginLog, 0)
	for _, item := range logs {
		if match(item) {
			filtered = append(filtered, item)
		}
	}
	ctx.JSON(http.StatusOK, filtered)
}

func queryTimeWindow(ctx *gin.Context) (time.Time, time.Time, error) {
	startRaw := firstQuery(ctx, "startTime", "start")
	if startRaw == "" {
		startRaw = "1970-01-01"
	}
	endRaw := firstQuery(ctx, "endTime", "end")
	if endRaw == "" {
		endRaw = "2100-01-01"
	}
	start, err1 := parseFlexibleTime(startRaw)
	end, err2 := parseFlexibleTime(endRaw)
	if err1 != nil {
		return time.Time{}, time.Time{}, err1
	}
	if err2 != nil {
		return time.Time{}, time.Time{}, err2
	}
	if len(strings.TrimSpace(endRaw)) == 10 {
		end = end.Add(24*time.Hour - time.Second)
	}
	return start, end, nil
}

func firstQuery(ctx *gin.Context, names ...string) string {
	for _, name := range names {
		if value := strings.TrimSpace(ctx.Query(name)); value != "" {
			return value
		}
	}
	return ""
}
