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

// DeductionInformationController 控制器层
type DeductionInformationController struct {
	deductionService *service.DeductionInformationService
}

// NewDeductionInformationController 构造函数
func NewDeductionInformationController(deductionService *service.DeductionInformationService) *DeductionInformationController {
	return &DeductionInformationController{
		deductionService: deductionService,
	}
}

// RegisterRoutes 注册路由
func (c *DeductionInformationController) RegisterRoutes(r *gin.Engine) {
	group := r.Group("/api/deductions")

	group.POST("", c.CreateDeduction)
	group.GET("", c.GetAllDeductions)
	group.GET("/:deductionId", c.GetDeductionById)
	group.PUT("/:deductionId", c.UpdateDeduction)
	group.DELETE("/:deductionId", c.DeleteDeduction)
	group.GET("/handler/:handler", c.GetDeductionsByHandler)
	group.GET("/timeRange", c.GetDeductionsByTimeRange)
	group.GET("/by-handler", c.SearchByHandler)
	group.GET("/by-time-range", c.SearchByDeductionTimeRange)
}

// CreateDeduction 创建扣除记录（仅限管理员）
func (c *DeductionInformationController) CreateDeduction(ctx *gin.Context) {
	var deduction domain.DeductionInformation
	idempotencyKey := ctx.Query("idempotencyKey")

	if err := ctx.ShouldBindJSON(&deduction); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid input"})
		return
	}

	log.Printf("Attempting to create deduction with idempotency key: %s", idempotencyKey)
	if err := c.deductionService.CheckAndInsertIdempotency(idempotencyKey, &deduction, "create"); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	log.Println("Deduction created successfully.")
	ctx.Status(http.StatusCreated)
}

// GetDeductionById 根据ID获取扣除记录
func (c *DeductionInformationController) GetDeductionById(ctx *gin.Context) {
	deductionId := ctx.Param("deductionId")

	deduction, err := c.deductionService.GetDeductionById(deductionId)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "deduction not found"})
		return
	}
	ctx.JSON(http.StatusOK, deduction)
}

// GetAllDeductions 获取所有扣除记录
func (c *DeductionInformationController) GetAllDeductions(ctx *gin.Context) {
	deductions, err := c.deductionService.GetAllDeductions()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, deductions)
}

// UpdateDeduction 更新扣除记录（仅限管理员）
func (c *DeductionInformationController) UpdateDeduction(ctx *gin.Context) {
	deductionId := ctx.Param("deductionId")
	idempotencyKey := ctx.Query("idempotencyKey")

	var updated domain.DeductionInformation
	if err := ctx.ShouldBindJSON(&updated); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid input"})
		return
	}

	existing, err := c.deductionService.GetDeductionById(deductionId)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "deduction not found"})
		return
	}

	// 更新字段
	existing.Remarks = updated.Remarks
	existing.Handler = updated.Handler
	existing.DeductedPoints = updated.DeductedPoints
	existing.DeductionTime = updated.DeductionTime
	existing.Approver = updated.Approver

	if err := c.deductionService.CheckAndInsertIdempotency(idempotencyKey, existing, "update"); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx.Status(http.StatusOK)
}

// DeleteDeduction 删除扣除记录（仅限管理员）
func (c *DeductionInformationController) DeleteDeduction(ctx *gin.Context) {
	deductionId := ctx.Param("deductionId")

	if err := c.deductionService.DeleteDeduction(deductionId); err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "deduction not found"})
		return
	}
	ctx.Status(http.StatusNoContent)
}

// GetDeductionsByHandler 根据处理人获取扣除记录
func (c *DeductionInformationController) GetDeductionsByHandler(ctx *gin.Context) {
	handler := ctx.Param("handler")
	deductions, err := c.deductionService.GetDeductionsByHandler(handler)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, deductions)
}

// GetDeductionsByTimeRange 根据时间范围获取扣除记录
func (c *DeductionInformationController) GetDeductionsByTimeRange(ctx *gin.Context) {
	startStr := ctx.Query("startTime")
	endStr := ctx.Query("endTime")

	start, err1 := time.Parse("2006-01-02T15:04:05", startStr)
	end, err2 := time.Parse("2006-01-02T15:04:05", endStr)
	if err1 != nil || err2 != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid time format"})
		return
	}

	deductions, err := c.deductionService.GetDeductionsByTimeRange(start, end)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, deductions)
}

// SearchByHandler 按处理人搜索扣除记录
func (c *DeductionInformationController) SearchByHandler(ctx *gin.Context) {
	handler := ctx.Query("handler")
	maxSuggestions := 10
	if ctx.Query("maxSuggestions") != "" {
		if n, err := strconv.Atoi(ctx.Query("maxSuggestions")); err == nil {
			maxSuggestions = n
		}
	}

	log.Printf("Searching deductions by handler: %s, max=%d", handler, maxSuggestions)
	results, err := c.deductionService.SearchByHandler(handler, maxSuggestions)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if len(results) == 0 {
		ctx.Status(http.StatusNoContent)
		return
	}
	ctx.JSON(http.StatusOK, results)
}

// SearchByDeductionTimeRange 按时间范围搜索扣除记录
func (c *DeductionInformationController) SearchByDeductionTimeRange(ctx *gin.Context) {
	startStr := ctx.Query("startTime")
	endStr := ctx.Query("endTime")
	maxSuggestions := 10
	if ctx.Query("maxSuggestions") != "" {
		if n, err := strconv.Atoi(ctx.Query("maxSuggestions")); err == nil {
			maxSuggestions = n
		}
	}

	start, err1 := time.Parse("2006-01-02T15:04:05", startStr)
	end, err2 := time.Parse("2006-01-02T15:04:05", endStr)
	if err1 != nil || err2 != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid time format"})
		return
	}

	log.Printf("Searching deductions by time range: %s -> %s, max=%d", startStr, endStr, maxSuggestions)
	results, err := c.deductionService.SearchByDeductionTimeRange(start, end, maxSuggestions)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if len(results) == 0 {
		ctx.Status(http.StatusNoContent)
		return
	}
	ctx.JSON(http.StatusOK, results)
}
