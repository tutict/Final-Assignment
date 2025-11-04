package handler

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/service"
)

// TrafficViolationHandler 负责处理交通违法相关的 HTTP 请求
type TrafficViolationHandler struct {
	Service *service.TrafficViolationService
}

// NewTrafficViolationHandler 构造函数
func NewTrafficViolationHandler(s *service.TrafficViolationService) *TrafficViolationHandler {
	return &TrafficViolationHandler{Service: s}
}

// GetViolationTypeCounts GET /api/traffic-violations/violation-types
func (h *TrafficViolationHandler) GetViolationTypeCounts(c *gin.Context) {
	startTime := c.Query("startTime")
	driverName := c.Query("driverName")
	licensePlate := c.Query("licensePlate")

	log.Printf("[INFO] Fetching violation type counts: startTime=%s, driverName=%s, licensePlate=%s",
		startTime, driverName, licensePlate)

	counts, err := h.Service.GetViolationTypeCounts(startTime, driverName, licensePlate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error_code": 500, "message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, counts)
}

// GetTimeSeriesData GET /api/traffic-violations/time-series
func (h *TrafficViolationHandler) GetTimeSeriesData(c *gin.Context) {
	startTime := c.Query("startTime")
	driverName := c.Query("driverName")

	log.Printf("[INFO] Fetching time series data: startTime=%s, driverName=%s", startTime, driverName)

	data, err := h.Service.GetTimeSeriesData(startTime, driverName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error_code": 500, "message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, data)
}

// GetAppealReasonCounts GET /api/traffic-violations/appeal-reasons
func (h *TrafficViolationHandler) GetAppealReasonCounts(c *gin.Context) {
	startTime := c.Query("startTime")
	appealReason := c.Query("appealReason")

	log.Printf("[INFO] Fetching appeal reason counts: startTime=%s, appealReason=%s",
		startTime, appealReason)

	counts, err := h.Service.GetAppealReasonCounts(startTime, appealReason)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error_code": 500, "message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, counts)
}

// GetFinePaymentStatus GET /api/traffic-violations/fine-payment-status
func (h *TrafficViolationHandler) GetFinePaymentStatus(c *gin.Context) {
	startTime := c.Query("startTime")

	log.Printf("[INFO] Fetching fine payment status: startTime=%s", startTime)

	status, err := h.Service.GetFinePaymentStatus(startTime)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error_code": 500, "message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, status)
}
