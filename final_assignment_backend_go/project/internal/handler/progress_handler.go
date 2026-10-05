package handler

import (
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
	service "final_assignment_backend_go/project/internal/service/shared"
)

type ProgressHandler struct {
	svc ProgressService
}

// NewProgressHandler 构造函数
func NewProgressHandler(svc ProgressService) *ProgressHandler {
	return &ProgressHandler{svc: svc}
}

// RegisterRoutes 注册路由
func (h *ProgressHandler) RegisterRoutes(r *gin.Engine) {
	api := r.Group("/api/progress")
	{
		api.POST("", h.CreateProgress)
		api.GET("", h.GetAllProgress)
		api.GET("/by-username", h.GetProgressByUsername)
		api.GET("/status", h.GetProgressByStatus)
		api.GET("/status/:status", h.GetProgressByStatus)
		api.GET("/timeRange", h.GetProgressByTimeRange)
		api.GET("/:progressId", h.GetProgress)
		api.PUT("/:progressId/status", h.UpdateProgressStatus)
		api.PUT("/:progressId", h.UpdateProgress)
		api.DELETE("/:progressId", h.DeleteProgress)
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

	progress = normalizeProgressPayload(progress)
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
	items, err := h.visibleProgress(c)
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
	newStatus := normalizeProgressStatus(c.Query("newStatus"))

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
	if status == "" {
		status = c.Query("status")
	}
	status = normalizeProgressStatus(status)
	if !isValidStatus(status) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid status"})
		return
	}
	items, err := h.visibleProgress(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	filtered := make([]domain.ProgressItem, 0)
	for _, item := range items {
		if normalizeProgressStatus(item.Status) == status {
			filtered = append(filtered, item)
		}
	}
	c.JSON(http.StatusOK, filtered)
}

// GetProgressByTimeRange GET /api/progress/timeRange?startTime=2023-01-01T00:00:00&endTime=2023-12-31T23:59:59
func (h *ProgressHandler) GetProgressByTimeRange(c *gin.Context) {
	startTime, err1 := parseFlexibleTime(c.Query("startTime"))
	endRaw := c.Query("endTime")
	endTime, err2 := parseFlexibleTime(endRaw)
	if err1 != nil || err2 != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid time format"})
		return
	}
	if len(strings.TrimSpace(endRaw)) == 10 {
		endTime = endTime.Add(24*time.Hour - time.Second)
	}
	visible, err := h.visibleProgress(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	items := make([]domain.ProgressItem, 0)
	for _, item := range visible {
		if !item.SubmitTime.Before(startTime) && !item.SubmitTime.After(endTime) {
			items = append(items, item)
		}
	}

	c.JSON(http.StatusOK, items)
}

// 工具函数：验证状态
func isValidStatus(status string) bool {
	switch normalizeProgressStatus(status) {
	case "Pending", "Processing", "Completed", "Failed", "Archived":
		return true
	default:
		return false
	}
}

func normalizeProgressStatus(raw string) string {
	switch strings.ToUpper(strings.TrimSpace(raw)) {
	case "SUCCESS", "SUCCEEDED", "COMPLETED", "COMPLETE", "DONE", "PAID", "APPROVED":
		return "Completed"
	case "FAILED", "FAILURE", "ERROR", "REJECTED":
		return "Failed"
	case "PROCESSING", "RUNNING", "IN_PROGRESS":
		return "Processing"
	case "ARCHIVED":
		return "Archived"
	case "PENDING", "":
		return "Pending"
	default:
		return strings.TrimSpace(raw)
	}
}

func normalizeProgressPayload(item domain.ProgressItem) domain.ProgressItem {
	item.Status = normalizeProgressStatus(item.Status)
	return item
}

func (h *ProgressHandler) visibleProgress(c *gin.Context) ([]domain.ProgressItem, error) {
	requested := strings.TrimSpace(c.Query("username"))
	if Unscoped(c, ResourceProgress) {
		if requested != "" {
			return h.svc.GetProgressByUsername(requested)
		}
		return h.svc.GetAllProgress()
	}
	username := c.GetString("username")
	if requested != "" && requested != username {
		return []domain.ProgressItem{}, nil
	}
	return h.svc.GetProgressByUsername(username)
}

func (h *ProgressHandler) GetProgress(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("progressId"))
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid progress id"})
		return
	}
	items, err := h.visibleProgress(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	for _, item := range items {
		if item.ID == id {
			c.JSON(http.StatusOK, item)
			return
		}
	}
	c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
}

func (h *ProgressHandler) UpdateProgress(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("progressId"))
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid progress id"})
		return
	}
	var payload struct {
		Title          string    `json:"title"`
		BusinessType   string    `json:"businessType"`
		Status         string    `json:"status"`
		BusinessStatus string    `json:"businessStatus"`
		SubmitTime     time.Time `json:"submitTime"`
		CreatedAt      time.Time `json:"createdAt"`
		Details        string    `json:"details"`
		RequestParams  string    `json:"requestParams"`
		Username       string    `json:"username"`
	}
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}
	if _, err := h.findVisible(c, id); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	status := payload.BusinessStatus
	if status == "" {
		status = payload.Status
	}
	title := payload.Title
	if title == "" {
		title = payload.BusinessType
	}
	details := payload.Details
	if details == "" {
		details = payload.RequestParams
	}
	when := payload.SubmitTime
	if when.IsZero() {
		when = payload.CreatedAt
	}
	updated, err := h.svc.UpdateProgress(&domain.ProgressItem{
		ID:         id,
		Title:      title,
		Status:     normalizeProgressStatus(status),
		SubmitTime: when,
		Details:    details,
		Username:   payload.Username,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, updated)
}

func (h *ProgressHandler) findVisible(c *gin.Context, id int) (domain.ProgressItem, error) {
	items, err := h.visibleProgress(c)
	if err != nil {
		return domain.ProgressItem{}, err
	}
	for _, item := range items {
		if item.ID == id {
			return item, nil
		}
	}
	return domain.ProgressItem{}, errNotVisible
}

var errNotVisible = errString("progress not visible")

type errString string

func (e errString) Error() string { return string(e) }
