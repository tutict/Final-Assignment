package handler

import (
	"fmt"
	"log"
	"net/http"
	"strings"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
)

type FineController struct {
	FineService FineInformationService
}

// NewFineController 构造函数
func NewFineController(fineService FineInformationService) *FineController {
	return &FineController{FineService: fineService}
}

// CreateFine POST /api/fines
func (fc *FineController) CreateFine(c *gin.Context) {
	if !requireFinanceStaff(c) {
		return
	}
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
	if err != nil || !fc.FineService.CanAccess(c.GetString("username"), elevatedRequester(c), fine) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Fine not found"})
		return
	}
	c.JSON(http.StatusOK, fine)
}

// GetAllFines GET /api/fines
func (fc *FineController) GetAllFines(c *gin.Context) {
	fines, err := fc.FineService.ListForRequester(c.GetString("username"), elevatedRequester(c))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get fines"})
		return
	}
	c.JSON(http.StatusOK, fines)
}

// UpdateFine PUT /api/fines/:fineId
func (fc *FineController) UpdateFine(c *gin.Context) {
	if !requireFinanceStaff(c) {
		return
	}
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
	if !requireFinanceStaff(c) {
		return
	}
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
	if payee == "" {
		payee = c.Query("handler")
	}
	fines, err := fc.FineService.GetFinesByPayee(payee)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get fines"})
		return
	}
	c.JSON(http.StatusOK, fc.FineService.FilterForRequester(c.GetString("username"), elevatedRequester(c), fines))
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
	c.JSON(http.StatusOK, fc.FineService.FilterForRequester(c.GetString("username"), elevatedRequester(c), fines))
}

// GetFineByReceiptNumber GET /api/fines/receiptNumber/:receiptNumber
func (fc *FineController) GetFineByReceiptNumber(c *gin.Context) {
	receiptNumber := c.Param("receiptNumber")
	fine, err := fc.FineService.GetFineByReceiptNumber(receiptNumber)
	if err != nil || !fc.FineService.CanAccess(c.GetString("username"), elevatedRequester(c), fine) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Fine not found"})
		return
	}
	c.JSON(http.StatusOK, fine)
}

// SearchByFineTimeRange GET /api/fines/by-time-range?startTime=2024-01-01T00:00:00&endTime=2024-12-31T23:59:59&maxSuggestions=10
func (fc *FineController) SearchByFineTimeRange(c *gin.Context) {
	startStr := c.Query("startTime")
	if startStr == "" {
		startStr = c.Query("startDate")
	}
	endStr := c.Query("endTime")
	if endStr == "" {
		endStr = c.Query("endDate")
	}
	maxSuggestions := c.DefaultQuery("maxSuggestions", "10")

	startTime, err1 := parseFlexibleTime(startStr)
	endTime, err2 := parseFlexibleTime(endStr)
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

	c.JSON(http.StatusOK, fc.FineService.FilterForRequester(c.GetString("username"), elevatedRequester(c), results))
}


func (fc *FineController) GetFinesByDriverID(c *gin.Context) {
	driverID, err := strconv.Atoi(c.Param("driverId"))
	if err != nil || driverID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "driverId must be a positive integer"})
		return
	}
	if !elevatedRequester(c) {
		fines, err := fc.FineService.ListForRequester(c.GetString("username"), false)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get fines"})
			return
		}
		c.JSON(http.StatusOK, fines)
		return
	}
	fines, err := fc.FineService.GetFinesByDriverID(driverID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get fines"})
		return
	}
	c.JSON(http.StatusOK, fines)
}

func (fc *FineController) GetFinesByOffenseID(c *gin.Context) {
	offenseID, err := strconv.Atoi(c.Param("offenseId"))
	if err != nil || offenseID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "offenseId must be a positive integer"})
		return
	}
	fines, err := fc.FineService.GetFinesByOffenseID(offenseID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get fines"})
		return
	}
	c.JSON(http.StatusOK, fc.FineService.FilterForRequester(c.GetString("username"), elevatedRequester(c), fines))
}

func (fc *FineController) SearchByPaymentStatus(c *gin.Context) {
	status := c.Query("status")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(c.DefaultQuery("size", "20"))
	fines, err := fc.FineService.SearchByPaymentStatus(status, page, size)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get fines"})
		return
	}
	c.JSON(http.StatusOK, fc.FineService.FilterForRequester(c.GetString("username"), elevatedRequester(c), fines))
}

func parseFlexibleTime(value string) (time.Time, error) {
	value = strings.TrimSpace(value)
	for _, layout := range []string{
		time.RFC3339,
		"2006-01-02T15:04:05",
		"2006-01-02 15:04:05",
		"2006-01-02",
	} {
		if parsed, err := time.Parse(layout, value); err == nil {
			return parsed, nil
		}
	}
	return time.Time{}, fmt.Errorf("invalid time: %s", value)
}
