package handler

import (
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/service"

	"final_assignment_backend_go/project/internal/domain"
)

// AppealHandler 对应 Java 的 AppealManagementController
type AppealHandler struct {
	appealService *service.AppealService
}

// NewAppealHandler 构造函数
func NewAppealHandler(appealService *service.AppealService) *AppealHandler {
	return &AppealHandler{appealService}
}

// CreateAppeal 创建新申诉（POST /api/appeals）
func (h *AppealHandler) CreateAppeal(c *gin.Context) {
	var appeal domain.AppealManagement
	idempotencyKey := c.Query("idempotencyKey")

	if err := c.ShouldBindJSON(&appeal); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	created, err := h.appealService.CheckAndInsertIdempotency(idempotencyKey, &appeal, "create")
	if err != nil {
		log.Printf("Error creating appeal: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, created)
}

// GetAppealByID 获取单个申诉（GET /api/appeals/:id）
func (h *AppealHandler) GetAppealByID(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid appeal ID"})
		return
	}

	appeal, err := h.appealService.GetAppealByID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, appeal)
}

// GetAllAppeals 获取所有申诉（GET /api/appeals）
func (h *AppealHandler) GetAllAppeals(c *gin.Context) {
	appeals, err := h.appealService.GetAllAppeals()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, appeals)
}

// UpdateAppeal 更新申诉（PUT /api/appeals/:id）
func (h *AppealHandler) UpdateAppeal(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid appeal ID"})
		return
	}

	var updated domain.AppealManagement
	idempotencyKey := c.Query("idempotencyKey")

	if err := c.ShouldBindJSON(&updated); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	updated.AppealID = int(uint(id))
	appeal, err := h.appealService.CheckAndInsertIdempotency(idempotencyKey, &updated, "update")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, appeal)
}

// DeleteAppeal 删除申诉（DELETE /api/appeals/:id）
func (h *AppealHandler) DeleteAppeal(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid appeal ID"})
		return
	}

	if err := h.appealService.DeleteAppeal(uint(id)); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

// GetAppealsByProcessStatus 按状态查询（GET /api/appeals/status/:status）
func (h *AppealHandler) GetAppealsByProcessStatus(c *gin.Context) {
	status := c.Param("status")
	appeals, err := h.appealService.GetAppealsByProcessStatus(status)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, appeals)
}

// GetAppealsByAppellantName 按姓名查询（GET /api/appeals/name/:name）
func (h *AppealHandler) GetAppealsByAppellantName(c *gin.Context) {
	name := c.Param("name")
	appeals, err := h.appealService.GetAppealsByAppellantName(name)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, appeals)
}

// GetOffenseByAppealID 获取申诉关联违章信息（GET /api/appeals/:id/offense）
func (h *AppealHandler) GetOffenseByAppealID(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid appeal ID"})
		return
	}

	offense, err := h.appealService.GetOffenseByAppealID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, offense)
}

// GetAppealsByIdCardNumber 按身份证号查询（GET /api/appeals/id-card/:idCard）
func (h *AppealHandler) GetAppealsByIdCardNumber(c *gin.Context) {
	idCard := c.Param("idCard")
	appeals, err := h.appealService.GetAppealsByIdCardNumber(idCard)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, appeals)
}

// GetAppealsByContactNumber 按联系电话查询（GET /api/appeals/contact/:number）
func (h *AppealHandler) GetAppealsByContactNumber(c *gin.Context) {
	contact := c.Param("number")
	appeals, err := h.appealService.GetAppealsByContactNumber(contact)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, appeals)
}

// GetAppealsByOffenseID 按违章ID查询（GET /api/appeals/offense/:offenseId）
func (h *AppealHandler) GetAppealsByOffenseID(c *gin.Context) {
	offenseID, err := strconv.Atoi(c.Param("offenseId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid offense ID"})
		return
	}

	appeals, err := h.appealService.GetAppealsByOffenseID(uint(offenseID))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, appeals)
}

// GetAppealsByTimeRange 按时间范围查询（GET /api/appeals/time-range?start=...&end=...）
func (h *AppealHandler) GetAppealsByTimeRange(c *gin.Context) {
	startStr := c.Query("start")
	endStr := c.Query("end")

	start, err1 := time.Parse(time.RFC3339, startStr)
	end, err2 := time.Parse(time.RFC3339, endStr)
	if err1 != nil || err2 != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid time format"})
		return
	}

	appeals, err := h.appealService.GetAppealsByTimeRange(start, end)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, appeals)
}

// CountAppealsByStatus 按状态统计数量（GET /api/appeals/count/status/:status）
func (h *AppealHandler) CountAppealsByStatus(c *gin.Context) {
	status := c.Param("status")
	count, err := h.appealService.CountAppealsByStatus(status)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"count": count})
}
