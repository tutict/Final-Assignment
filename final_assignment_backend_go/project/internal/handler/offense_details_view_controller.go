package handler

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/service"
)

// OffenseDetailsViewServiceContract 处理器侧的违法详情视图服务契约。
type OffenseDetailsViewServiceContract interface {
	GetOffenseDetail(offenseID int) (*service.OffenseDetailResponse, error)
}

// OffenseDetailsViewController 对齐 Spring 的 OffenseDetailsController（/api/view/offenses）。
type OffenseDetailsViewController struct {
	Service OffenseDetailsViewServiceContract
}

func NewOffenseDetailsViewController(view OffenseDetailsViewServiceContract) *OffenseDetailsViewController {
	return &OffenseDetailsViewController{Service: view}
}

// RegisterRoutes 注册 /api/view/offenses 路由。
func (c *OffenseDetailsViewController) RegisterRoutes(group *gin.RouterGroup) {
	api := group.Group("/view/offenses")

	api.GET("/:offenseId", c.getDetails)
}

// GET /api/view/offenses/:offenseId
func (c *OffenseDetailsViewController) getDetails(ctx *gin.Context) {
	offenseID, err := strconv.Atoi(ctx.Param("offenseId"))
	if err != nil || offenseID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid offense ID"})
		return
	}
	detail, err := c.Service.GetOffenseDetail(offenseID)
	if err != nil {
		if errors.Is(err, service.ErrNotFound) {
			ctx.JSON(http.StatusNotFound, apiError("OFFENSE_NOT_FOUND", "Offense not found: "+ctx.Param("offenseId")))
			return
		}
		ctx.JSON(http.StatusInternalServerError, apiError("INTERNAL_ERROR", "Failed to load offense details"))
		return
	}
	ctx.JSON(http.StatusOK, apiOK(detail))
}
