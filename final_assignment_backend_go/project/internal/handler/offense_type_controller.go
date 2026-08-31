package handler

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"
)

// OffenseTypeDictServiceContract 处理器侧的违法类型字典服务契约。
type OffenseTypeDictServiceContract interface {
	CheckAndInsertIdempotency(string, *domain.OffenseTypeDict, string) error
	CreateDict(*domain.OffenseTypeDict) (*domain.OffenseTypeDict, error)
	DeleteDict(int) error
	FindAll() ([]domain.OffenseTypeDict, error)
	FindByID(int) (*domain.OffenseTypeDict, error)
	SearchByCategory(string, int, int) ([]domain.OffenseTypeDict, error)
	SearchByDeductedPointsRange(int, int, int, int) ([]domain.OffenseTypeDict, error)
	SearchByOffenseCodeFuzzy(string, int, int) ([]domain.OffenseTypeDict, error)
	SearchByOffenseCodePrefix(string, int, int) ([]domain.OffenseTypeDict, error)
	SearchByOffenseNameFuzzy(string, int, int) ([]domain.OffenseTypeDict, error)
	SearchByOffenseNamePrefix(string, int, int) ([]domain.OffenseTypeDict, error)
	SearchBySeverityLevel(string, int, int) ([]domain.OffenseTypeDict, error)
	SearchByStandardFineAmountRange(float64, float64, int, int) ([]domain.OffenseTypeDict, error)
	SearchByStatus(string, int, int) ([]domain.OffenseTypeDict, error)
	UpdateDict(*domain.OffenseTypeDict) error
}

// OffenseTypeController 对齐 Spring 的 OffenseTypeController（/api/offense-types）。
type OffenseTypeController struct {
	Service OffenseTypeDictServiceContract
}

func NewOffenseTypeController(dictService OffenseTypeDictServiceContract) *OffenseTypeController {
	return &OffenseTypeController{Service: dictService}
}

// RegisterRoutes 注册 /api/offense-types 路由。
func (c *OffenseTypeController) RegisterRoutes(group *gin.RouterGroup) {
	api := group.Group("/offense-types")

	api.POST("", c.create)
	api.GET("", c.list)
	api.GET("/search/code/prefix", c.searchByCodePrefix)
	api.GET("/search/code/fuzzy", c.searchByCodeFuzzy)
	api.GET("/search/name/prefix", c.searchByNamePrefix)
	api.GET("/search/name/fuzzy", c.searchByNameFuzzy)
	api.GET("/search/category", c.searchByCategory)
	api.GET("/search/severity", c.searchBySeverity)
	api.GET("/search/status", c.searchByStatus)
	api.GET("/search/fine-range", c.searchByFineRange)
	api.GET("/search/points-range", c.searchByPointsRange)
	api.PUT("/:typeId", c.update)
	api.DELETE("/:typeId", c.delete)
	api.GET("/:typeId", c.get)
}

// POST /api/offense-types
func (c *OffenseTypeController) create(ctx *gin.Context) {
	var dict domain.OffenseTypeDict
	if err := ctx.ShouldBindJSON(&dict); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}
	if err := c.Service.CheckAndInsertIdempotency(idempotencyKeyHeader(ctx), &dict, "create"); err != nil {
		if errors.Is(err, service.ErrOffenseTypeDuplicate) {
			ctx.JSON(http.StatusAlreadyReported, gin.H{"success": true, "data": nil})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusCreated, &dict)
}

// PUT /api/offense-types/:typeId
func (c *OffenseTypeController) update(ctx *gin.Context) {
	typeID, err := strconv.Atoi(ctx.Param("typeId"))
	if err != nil || typeID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid type ID"})
		return
	}
	var dict domain.OffenseTypeDict
	if err := ctx.ShouldBindJSON(&dict); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}
	dict.TypeID = typeID
	if err := c.Service.CheckAndInsertIdempotency(idempotencyKeyHeader(ctx), &dict, "update"); err != nil {
		if errors.Is(err, service.ErrOffenseTypeDuplicate) {
			ctx.JSON(http.StatusAlreadyReported, gin.H{"success": true, "data": nil})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, &dict)
}

// DELETE /api/offense-types/:typeId
func (c *OffenseTypeController) delete(ctx *gin.Context) {
	typeID, err := strconv.Atoi(ctx.Param("typeId"))
	if err != nil || typeID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid type ID"})
		return
	}
	if err := c.Service.DeleteDict(typeID); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete offense type"})
		return
	}
	ctx.Status(http.StatusNoContent)
}

// GET /api/offense-types/:typeId
func (c *OffenseTypeController) get(ctx *gin.Context) {
	typeID, err := strconv.Atoi(ctx.Param("typeId"))
	if err != nil || typeID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid type ID"})
		return
	}
	dict, err := c.Service.FindByID(typeID)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "offense type not found"})
		return
	}
	ctx.JSON(http.StatusOK, dict)
}

// GET /api/offense-types
func (c *OffenseTypeController) list(ctx *gin.Context) {
	dicts, err := c.Service.FindAll()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list offense types"})
		return
	}
	ctx.JSON(http.StatusOK, dicts)
}

// GET /api/offense-types/search/code/prefix?offenseCode=
func (c *OffenseTypeController) searchByCodePrefix(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	dicts, err := c.Service.SearchByOffenseCodePrefix(ctx.Query("offenseCode"), page, size)
	dictResult(ctx, dicts, err)
}

// GET /api/offense-types/search/code/fuzzy?offenseCode=
func (c *OffenseTypeController) searchByCodeFuzzy(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	dicts, err := c.Service.SearchByOffenseCodeFuzzy(ctx.Query("offenseCode"), page, size)
	dictResult(ctx, dicts, err)
}

// GET /api/offense-types/search/name/prefix?offenseName=
func (c *OffenseTypeController) searchByNamePrefix(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	dicts, err := c.Service.SearchByOffenseNamePrefix(ctx.Query("offenseName"), page, size)
	dictResult(ctx, dicts, err)
}

// GET /api/offense-types/search/name/fuzzy?offenseName=
func (c *OffenseTypeController) searchByNameFuzzy(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	dicts, err := c.Service.SearchByOffenseNameFuzzy(ctx.Query("offenseName"), page, size)
	dictResult(ctx, dicts, err)
}

// GET /api/offense-types/search/category?category=
func (c *OffenseTypeController) searchByCategory(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	dicts, err := c.Service.SearchByCategory(ctx.Query("category"), page, size)
	dictResult(ctx, dicts, err)
}

// GET /api/offense-types/search/severity?severityLevel=
func (c *OffenseTypeController) searchBySeverity(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	dicts, err := c.Service.SearchBySeverityLevel(ctx.Query("severityLevel"), page, size)
	dictResult(ctx, dicts, err)
}

// GET /api/offense-types/search/status?status=
func (c *OffenseTypeController) searchByStatus(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	dicts, err := c.Service.SearchByStatus(ctx.Query("status"), page, size)
	dictResult(ctx, dicts, err)
}

// GET /api/offense-types/search/fine-range?minAmount=&maxAmount=
func (c *OffenseTypeController) searchByFineRange(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	minAmount, errMin := strconv.ParseFloat(ctx.Query("minAmount"), 64)
	maxAmount, errMax := strconv.ParseFloat(ctx.Query("maxAmount"), 64)
	if errMin != nil || errMax != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "minAmount and maxAmount must be numbers"})
		return
	}
	dicts, err := c.Service.SearchByStandardFineAmountRange(minAmount, maxAmount, page, size)
	dictResult(ctx, dicts, err)
}

// GET /api/offense-types/search/points-range?minPoints=&maxPoints=
func (c *OffenseTypeController) searchByPointsRange(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	minPoints, errMin := strconv.Atoi(ctx.Query("minPoints"))
	maxPoints, errMax := strconv.Atoi(ctx.Query("maxPoints"))
	if errMin != nil || errMax != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "minPoints and maxPoints must be integers"})
		return
	}
	dicts, err := c.Service.SearchByDeductedPointsRange(minPoints, maxPoints, page, size)
	dictResult(ctx, dicts, err)
}

func dictResult(ctx *gin.Context, dicts []domain.OffenseTypeDict, err error) {
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "query failed"})
		return
	}
	ctx.JSON(http.StatusOK, dicts)
}
