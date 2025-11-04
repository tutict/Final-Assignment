package handler

import (
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"
)

type ProgressHandler struct {
	svc *service.ProgressService
}

// NewProgressHandler 构造函数
func NewProgressHandler(svc *service.ProgressService) *ProgressHandler {
	return &ProgressHandler{svc: svc}
}

// RegisterRoutes 注册路由
func (h *ProgressHandler) RegisterRoutes(r *gin.Engine) {
	api := r.Group("/api/progress")
	{
		api.POST("", h.RequireRole("USER"), h.CreateProgress)
		api.GET("", h.RequireRole("ADMIN"), h.GetAllProgress)
		api.GET("", h.RequireRole("USER"), h.GetProgressByUsername) // ?username=
		api.PUT("/:progressId/status", h.RequireRole("ADMIN"), h.UpdateProgressStatus)
		api.DELETE("/:progressId", h.RequireRole("ADMIN"), h.DeleteProgress)
		api.GET("/status/:status", h.RequireRole("ADMIN", "USER"), h.GetProgressByStatus)
		api.GET("/timeRange", h.RequireRole("ADMIN", "USER"), h.GetProgressByTimeRange)
	}
}

// RequireRole 伪角色鉴权中间件（实际应由 JWT 实现）
func (h *ProgressHandler) RequireRole(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole := c.GetString("role") // 假设JWT解析后放入context

		for _, r := range roles {
			if r == userRole {
				c.Next()
				return
			}
		}

		c.JSON(http.StatusForbidden, gin.H{"error": "access denied"})
		c.Abort()
	}
}

// ---------------- CRUD 接口 ----------------

// CreateProgress POST /api/progress
func (h *ProgressHandler) CreateProgress(c *gin.Context) {
	var progress domain.ProgressItem
	if err := c.ShouldBindJSON(&progress); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	log.Printf("Attempting to create progress item with title: %s", progress.Title)
	saved, err := h.svc.CreateProgress(&progress)
	if err != nil {
		log.Printf("Error creating progress: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "create failed"})
		return
	}
	log.Printf("Progress item created successfully with ID: %d", saved.ID)
	c.JSON(http.StatusCreated, saved)
}

// GetAllProgress GET /api/progress (admin)
func (h *ProgressHandler) GetAllProgress(c *gin.Context) {
	items, err := h.svc.GetAllProgress()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, items)
}

// GetProgressByUsername GET /api/progress?username=xxx
func (h *ProgressHandler) GetProgressByUsername(c *gin.Context) {
	username := c.Query("username")
	if username == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "username required"})
		return
	}

	items, err := h.svc.GetProgressByUsername(username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, items)
}

// UpdateProgressStatus PUT /api/progress/:progressId/status?newStatus=PROCESSING
func (h *ProgressHandler) UpdateProgressStatus(c *gin.Context) {
	id, _ := strconv.Atoi(c.Param("progressId"))
	newStatus := c.Query("newStatus")

	if !isValidStatus(newStatus) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid status"})
		return
	}

	item, err := h.svc.UpdateProgressStatus(id, newStatus)
	if err != nil {
		if err == service.ErrNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	log.Printf("Progress item %d updated to status %s", id, newStatus)
	c.JSON(http.StatusOK, item)
}

// DeleteProgress DELETE /api/progress/:progressId
func (h *ProgressHandler) DeleteProgress(c *gin.Context) {
	id, _ := strconv.Atoi(c.Param("progressId"))
	if err := h.svc.DeleteProgress(id); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	log.Printf("Progress item %d deleted successfully", id)
	c.Status(http.StatusNoContent)
}

// GetProgressByStatus GET /api/progress/status/:status
func (h *ProgressHandler) GetProgressByStatus(c *gin.Context) {
	status := c.Param("status")
	if !isValidStatus(status) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid status"})
		return
	}

	items, err := h.svc.GetProgressByStatus(status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, items)
}

// GetProgressByTimeRange GET /api/progress/timeRange?startTime=2023-01-01T00:00:00&endTime=2023-12-31T23:59:59
func (h *ProgressHandler) GetProgressByTimeRange(c *gin.Context) {
	startStr := c.Query("startTime")
	endStr := c.Query("endTime")

	startTime, err1 := time.Parse("2006-01-02T15:04:05", startStr)
	endTime, err2 := time.Parse("2006-01-02T15:04:05", endStr)

	if err1 != nil || err2 != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid time format"})
		return
	}

	items, err := h.svc.GetProgressByTimeRange(startTime, endTime)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, items)
}

// 工具函数：验证状态
func isValidStatus(status string) bool {
	switch status {
	case "PENDING", "PROCESSING", "COMPLETED", "ARCHIVED":
		return true
	default:
		return false
	}
}
