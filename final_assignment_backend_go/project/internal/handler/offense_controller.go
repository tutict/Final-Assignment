package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"

	"final_assignment_backend_go/project/internal/service"
)

type OffenseInformationController struct {
	Service *service.OffenseInformationService
}

// RegisterRoutes 注册路由
func (c *OffenseInformationController) RegisterRoutes(r *gin.RouterGroup) {
	api := r.Group("/api/offenses")

	api.POST("", c.createOffense)
	api.GET("/:offenseId", c.getOffenseByID)
	api.GET("", c.getAllOffenses)
	api.PUT("/:offenseId", c.updateOffense)
	api.DELETE("/:offenseId", c.deleteOffense)
	api.GET("/timeRange", c.getOffensesByTimeRange)
	api.GET("/by-offense-type", c.searchByOffenseType)
	api.GET("/by-driver-name", c.searchByDriverName)
	api.GET("/by-license-plate", c.searchByLicensePlate)
}

// POST /api/offenses
func (c *OffenseInformationController) createOffense(ctx *gin.Context) {
	var offense domain.OffenseInformation
	idempotencyKey := ctx.Query("idempotencyKey")

	if err := ctx.ShouldBindJSON(&offense); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	if err := c.Service.CheckAndInsertIdempotency(idempotencyKey, &offense, "create"); err != nil {
		ctx.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	ctx.Status(http.StatusCreated)
}

// GET /api/offenses/:offenseId
func (c *OffenseInformationController) getOffenseByID(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("offenseId"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid offense ID"})
		return
	}

	offense, err := c.Service.GetOffenseByID(id)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "offense not found"})
		return
	}

	ctx.JSON(http.StatusOK, offense)
}

// GET /api/offenses
func (c *OffenseInformationController) getAllOffenses(ctx *gin.Context) {
	offenses, err := c.Service.GetAllOffenses()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch offenses"})
		return
	}
	ctx.JSON(http.StatusOK, offenses)
}

// PUT /api/offenses/:offenseId
func (c *OffenseInformationController) updateOffense(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("offenseId"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid offense ID"})
		return
	}

	var updated domain.OffenseInformation
	if err := ctx.ShouldBindJSON(&updated); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	idempotencyKey := ctx.Query("idempotencyKey")
	updated.OffenseID = uint(id)

	if err := c.Service.CheckAndInsertIdempotency(idempotencyKey, &updated, "update"); err != nil {
		ctx.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, updated)
}

// DELETE /api/offenses/:offenseId
func (c *OffenseInformationController) deleteOffense(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("offenseId"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid offense ID"})
		return
	}

	if err := c.Service.DeleteOffense(id); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete offense"})
		return
	}

	ctx.Status(http.StatusNoContent)
}

// GET /api/offenses/timeRange
func (c *OffenseInformationController) getOffensesByTimeRange(ctx *gin.Context) {
	startStr := ctx.DefaultQuery("startTime", "1970-01-01")
	endStr := ctx.DefaultQuery("endTime", "2100-01-01")

	startTime, err := time.Parse("2006-01-02", startStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid startTime format"})
		return
	}
	endTime, err := time.Parse("2006-01-02", endStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid endTime format"})
		return
	}

	offenses, err := c.Service.GetOffensesByTimeRange(startTime, endTime)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "query failed"})
		return
	}
	ctx.JSON(http.StatusOK, offenses)
}

// GET /api/offenses/by-offense-type
func (c *OffenseInformationController) searchByOffenseType(ctx *gin.Context) {
	query := ctx.Query("query")
	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(ctx.DefaultQuery("size", "10"))

	results, err := c.Service.SearchByOffenseType(query, page, size)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "query failed"})
		return
	}

	if len(results) == 0 {
		ctx.Status(http.StatusNoContent)
		return
	}

	ctx.JSON(http.StatusOK, results)
}

// GET /api/offenses/by-driver-name
func (c *OffenseInformationController) searchByDriverName(ctx *gin.Context) {
	query := ctx.Query("query")
	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(ctx.DefaultQuery("size", "10"))

	results, err := c.Service.SearchByDriverName(query, page, size)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "query failed"})
		return
	}

	if len(results) == 0 {
		ctx.Status(http.StatusNoContent)
		return
	}

	ctx.JSON(http.StatusOK, results)
}

// GET /api/offenses/by-license-plate
func (c *OffenseInformationController) searchByLicensePlate(ctx *gin.Context) {
	query := ctx.Query("query")
	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(ctx.DefaultQuery("size", "10"))

	results, err := c.Service.SearchByLicensePlate(query, page, size)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "query failed"})
		return
	}

	if len(results) == 0 {
		ctx.Status(http.StatusNoContent)
		return
	}

	ctx.JSON(http.StatusOK, results)
}
