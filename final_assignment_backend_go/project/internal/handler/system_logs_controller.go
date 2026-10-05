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

// SystemLogsController 负责处理系统日志相关请求
type SystemLogsController struct {
	SystemLogsService SystemLogsService
	Requests          RequestHistorySource
}

type RequestHistorySource interface {
	ListSysRequestHistory() ([]domain.SysRequestHistory, error)
}

// NewSystemLogsController 创建新的控制器实例
func NewSystemLogsController(svc SystemLogsService) *SystemLogsController {
	return &SystemLogsController{SystemLogsService: svc}
}

func (ctrl *SystemLogsController) WithRequestHistory(source RequestHistorySource) *SystemLogsController {
	ctrl.Requests = source
	return ctrl
}

// RegisterRoutes 注册路由
func (ctrl *SystemLogsController) RegisterRoutes(r *gin.Engine) {
	ctrl.mountSystemLogs(r.Group("/api/systemLogs"))
	ctrl.mountSystemLogs(r.Group("/api/system/logs"))
}

func (ctrl *SystemLogsController) mountSystemLogs(group *gin.RouterGroup) {
	group.POST("", ctrl.CreateSystemLog)
	group.GET("", ctrl.GetAllSystemLogs)
	group.GET("/type/:logType", ctrl.GetSystemLogsByType)
	group.GET("/timeRange", ctrl.GetSystemLogsByTimeRange)
	group.GET("/operationUser/:operationUser", ctrl.GetSystemLogsByOperationUser)
	group.GET("/autocomplete/log-types/me", ctrl.GetLogTypeAutocompleteSuggestionsGlobally)
	group.GET("/autocomplete/operation-users/me", ctrl.GetOperationUserAutocompleteSuggestionsGlobally)
	group.GET("/overview", ctrl.GetSystemLogOverview)
	group.GET("/login/recent", ctrl.GetRecentLoginLogsAlias)
	group.GET("/operation/recent", ctrl.GetRecentOperationLogsAlias)
	group.GET("/requests/search/idempotency", ctrl.SearchRequestHistoryByIdempotency)
	group.GET("/requests/search/method", ctrl.SearchRequestHistoryByMethod)
	group.GET("/requests/search/url", ctrl.SearchRequestHistoryByURL)
	group.GET("/requests/search/business-type", ctrl.SearchRequestHistoryByBusinessType)
	group.GET("/requests/search/business-id", ctrl.SearchRequestHistoryByBusinessID)
	group.GET("/requests/search/status", ctrl.SearchRequestHistoryByStatus)
	group.GET("/requests/search/user", ctrl.SearchRequestHistoryByUser)
	group.GET("/requests/search/ip", ctrl.SearchRequestHistoryByIP)
	group.GET("/requests/search/time-range", ctrl.SearchRequestHistoryByTimeRange)
	group.GET("/requests/:historyId", ctrl.GetRequestHistory)
	group.GET("/:logId", ctrl.GetSystemLogByID)
	group.PUT("/:logId", ctrl.UpdateSystemLog)
	group.DELETE("/:logId", ctrl.DeleteSystemLog)
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
func (ctrl *SystemLogsController) GetSystemLogOverview(c *gin.Context) {
	logs, err := ctrl.SystemLogsService.GetAllSystemLogs()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"systemLogCount":   len(logs),
		"recentSystemLogs": firstLogs(logs, 10),
	})
}

func (ctrl *SystemLogsController) GetRecentLoginLogsAlias(c *gin.Context) {
	c.JSON(http.StatusOK, []any{})
}

func (ctrl *SystemLogsController) GetRecentOperationLogsAlias(c *gin.Context) {
	c.JSON(http.StatusOK, []any{})
}

func firstLogs(logs []domain.SystemLogs, limit int) []domain.SystemLogs {
	if len(logs) > limit {
		return logs[:limit]
	}
	return logs
}

func (ctrl *SystemLogsController) GetRequestHistory(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("historyId"), 10, 64)
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid history id"})
		return
	}
	rows, err := ctrl.requestHistory()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	for _, row := range rows {
		if row.ID == id {
			c.JSON(http.StatusOK, row)
			return
		}
	}
	c.JSON(http.StatusNotFound, gin.H{"error": "request history not found"})
}

func (ctrl *SystemLogsController) SearchRequestHistoryByIdempotency(c *gin.Context) {
	query := c.Query("key")
	ctrl.searchRequestHistory(c, func(row domain.SysRequestHistory) bool {
		return containsFold(row.IdempotencyKey, query)
	})
}

func (ctrl *SystemLogsController) SearchRequestHistoryByMethod(c *gin.Context) {
	query := c.Query("requestMethod")
	ctrl.searchRequestHistory(c, func(row domain.SysRequestHistory) bool {
		return strings.EqualFold(row.RequestMethod, query)
	})
}

func (ctrl *SystemLogsController) SearchRequestHistoryByURL(c *gin.Context) {
	query := c.Query("requestUrl")
	ctrl.searchRequestHistory(c, func(row domain.SysRequestHistory) bool {
		return hasPrefixFold(row.RequestURL, query)
	})
}

func (ctrl *SystemLogsController) SearchRequestHistoryByBusinessType(c *gin.Context) {
	query := c.Query("businessType")
	ctrl.searchRequestHistory(c, func(row domain.SysRequestHistory) bool {
		return containsFold(row.BusinessType, query)
	})
}

func (ctrl *SystemLogsController) SearchRequestHistoryByBusinessID(c *gin.Context) {
	id, err := strconv.ParseInt(c.Query("businessId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid business id"})
		return
	}
	ctrl.searchRequestHistory(c, func(row domain.SysRequestHistory) bool {
		return row.BusinessID != nil && *row.BusinessID == id
	})
}

func (ctrl *SystemLogsController) SearchRequestHistoryByStatus(c *gin.Context) {
	query := c.Query("status")
	ctrl.searchRequestHistory(c, func(row domain.SysRequestHistory) bool {
		return strings.EqualFold(row.BusinessStatus, query)
	})
}

func (ctrl *SystemLogsController) SearchRequestHistoryByUser(c *gin.Context) {
	id, err := strconv.ParseInt(c.Query("userId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user id"})
		return
	}
	ctrl.searchRequestHistory(c, func(row domain.SysRequestHistory) bool {
		return row.UserID != nil && *row.UserID == id
	})
}

func (ctrl *SystemLogsController) SearchRequestHistoryByIP(c *gin.Context) {
	query := c.Query("requestIp")
	ctrl.searchRequestHistory(c, func(row domain.SysRequestHistory) bool {
		return containsFold(row.RequestIP, query)
	})
}

func (ctrl *SystemLogsController) SearchRequestHistoryByTimeRange(c *gin.Context) {
	start, end, err := queryTimeWindow(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid time format"})
		return
	}
	ctrl.searchRequestHistory(c, func(row domain.SysRequestHistory) bool {
		return !row.CreatedAt.Before(start) && !row.CreatedAt.After(end)
	})
}

func (ctrl *SystemLogsController) searchRequestHistory(c *gin.Context, match func(domain.SysRequestHistory) bool) {
	rows, err := ctrl.requestHistory()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	filtered := make([]domain.SysRequestHistory, 0)
	for _, row := range rows {
		if match(row) {
			filtered = append(filtered, row)
		}
	}
	c.JSON(http.StatusOK, filtered)
}

func (ctrl *SystemLogsController) requestHistory() ([]domain.SysRequestHistory, error) {
	if ctrl.Requests == nil {
		return []domain.SysRequestHistory{}, nil
	}
	return ctrl.Requests.ListSysRequestHistory()
}
