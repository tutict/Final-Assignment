package handler

import (
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"
)

type FineController struct {
	FineService *service.FineInformationService
}

// NewFineController 构造函数
func NewFineController(fineService *service.FineInformationService) *FineController {
	return &FineController{FineService: fineService}
}

// CreateFine POST /api/fines
func (fc *FineController) CreateFine(c *gin.Context) {
	var fine domain.FineInformation
	idempotencyKey := c.Query("idempotencyKey")

	if err := c.ShouldBindJSON(&fine); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	if err := fc.FineService.CheckAndInsertIdempotency(idempotencyKey, &fine, "create"); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusCreated)
}

// GetFineByID GET /api/fines/:fineId
func (fc *FineController) GetFineByID(c *gin.Context) {
	fineID := c.Param("fineId")
	fine, err := fc.FineService.GetFineByID(fineID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Fine not found"})
		return
	}
	c.JSON(http.StatusOK, fine)
}

// GetAllFines GET /api/fines
func (fc *FineController) GetAllFines(c *gin.Context) {
	fines, err := fc.FineService.GetAllFines()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get fines"})
		return
	}
	c.JSON(http.StatusOK, fines)
}

// UpdateFine PUT /api/fines/:fineId
func (fc *FineController) UpdateFine(c *gin.Context) {
	fineID := c.Param("fineId")
	idempotencyKey := c.Query("idempotencyKey")

	var updatedFine domain.FineInformation
	if err := c.ShouldBindJSON(&updatedFine); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	existingFine, err := fc.FineService.GetFineByID(fineID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Fine not found"})
		return
	}

	updatedFine.FineID = existingFine.FineID
	if err := fc.FineService.CheckAndInsertIdempotency(idempotencyKey, &updatedFine, "update"); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, updatedFine)
}

// DeleteFine DELETE /api/fines/:fineId
func (fc *FineController) DeleteFine(c *gin.Context) {
	fineID := c.Param("fineId")
	if err := fc.FineService.DeleteFine(fineID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Fine not found"})
		return
	}
	c.Status(http.StatusNoContent)
}

// GetFinesByPayee GET /api/fines/payee/:payee
func (fc *FineController) GetFinesByPayee(c *gin.Context) {
	payee := c.Param("payee")
	fines, err := fc.FineService.GetFinesByPayee(payee)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get fines"})
		return
	}
	c.JSON(http.StatusOK, fines)
}

// GetFinesByTimeRange GET /api/fines/timeRange?startTime=1970-01-01&endTime=2100-01-01
func (fc *FineController) GetFinesByTimeRange(c *gin.Context) {
	startStr := c.Query("startTime")
	endStr := c.Query("endTime")

	startTime, err1 := time.Parse("2006-01-02", startStr)
	endTime, err2 := time.Parse("2006-01-02", endStr)
	if err1 != nil || err2 != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid date format, expected yyyy-MM-dd"})
		return
	}

	fines, err := fc.FineService.GetFinesByTimeRange(startTime, endTime)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get fines"})
		return
	}
	c.JSON(http.StatusOK, fines)
}

// GetFineByReceiptNumber GET /api/fines/receiptNumber/:receiptNumber
func (fc *FineController) GetFineByReceiptNumber(c *gin.Context) {
	receiptNumber := c.Param("receiptNumber")
	fine, err := fc.FineService.GetFineByReceiptNumber(receiptNumber)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Fine not found"})
		return
	}
	c.JSON(http.StatusOK, fine)
}

// SearchByFineTimeRange GET /api/fines/by-time-range?startTime=2024-01-01T00:00:00&endTime=2024-12-31T23:59:59&maxSuggestions=10
func (fc *FineController) SearchByFineTimeRange(c *gin.Context) {
	startStr := c.Query("startTime")
	endStr := c.Query("endTime")
	maxSuggestions := c.DefaultQuery("maxSuggestions", "10")

	startTime, err1 := time.Parse("2006-01-02T15:04:05", startStr)
	endTime, err2 := time.Parse("2006-01-02T15:04:05", endStr)
	if err1 != nil || err2 != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid datetime format, expected yyyy-MM-dd'T'HH:mm:ss"})
		return
	}

	results, err := fc.FineService.SearchByFineTimeRange(startTime, endTime, maxSuggestions)
	if err != nil {
		log.Printf("Error searching fines: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Server error"})
		return
	}

	if len(results) == 0 {
		c.Status(http.StatusNoContent)
		return
	}
	c.JSON(http.StatusOK, results)
}
