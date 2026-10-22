package handler

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
)

// ViolationCompatController 对齐 Spring TrafficViolationController 的 /api/violations 契约，
// 供 Flutter 的违章列表、按状态筛选与全链路详情使用。
type ViolationCompatController struct {
	Offenses   OffenseInformationService
	Fines      FineInformationService
	Payments   PaymentService
	Deductions DeductionInformationService
	Appeals    AppealService
}

func NewViolationCompatController(
	offenses OffenseInformationService,
	fines FineInformationService,
	payments PaymentService,
	deductions DeductionInformationService,
	appeals AppealService,
) *ViolationCompatController {
	return &ViolationCompatController{
		Offenses:   offenses,
		Fines:      fines,
		Payments:   payments,
		Deductions: deductions,
		Appeals:    appeals,
	}
}

func (c *ViolationCompatController) RegisterRoutes(router *gin.Engine) {
	group := router.Group("/api/violations")
	group.GET("", c.listViolations)
	group.GET("/status", c.listViolationsByStatus)
	group.GET("/:offenseId", c.violationDetails)
}

func (c *ViolationCompatController) listViolations(ctx *gin.Context) {
	offenses, err := c.Offenses.ListForRequester(ctx.GetString("username"), Unscoped(ctx, ResourceOffenses))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch violations"})
		return
	}
	ctx.JSON(http.StatusOK, nonNilOffenses(offenses))
}

func (c *ViolationCompatController) listViolationsByStatus(ctx *gin.Context) {
	status := strings.TrimSpace(ctx.Query("processStatus"))
	if status == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "processStatus is required"})
		return
	}

	page := parsePositiveInt(ctx.DefaultQuery("page", "1"), 1)
	size := parsePositiveInt(ctx.DefaultQuery("size", "20"), 20)
	if size > 200 {
		size = 200
	}

	offenses, err := c.Offenses.ListForRequester(ctx.GetString("username"), Unscoped(ctx, ResourceOffenses))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch violations"})
		return
	}

	matched := make([]domain.OffenseInformation, 0)
	for _, item := range offenses {
		if strings.EqualFold(item.ProcessStatus, status) {
			matched = append(matched, item)
		}
	}

	start := (page - 1) * size
	if start >= len(matched) {
		ctx.JSON(http.StatusOK, []domain.OffenseInformation{})
		return
	}
	end := start + size
	if end > len(matched) {
		end = len(matched)
	}
	ctx.JSON(http.StatusOK, matched[start:end])
}

func (c *ViolationCompatController) violationDetails(ctx *gin.Context) {
	offenseID, err := strconv.Atoi(ctx.Param("offenseId"))
	if err != nil || offenseID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid offense ID"})
		return
	}

	offense, err := c.Offenses.GetOffenseByID(offenseID)
	if err != nil || offense == nil || !c.Offenses.CanAccess(ctx.GetString("username"), Unscoped(ctx, ResourceOffenses), offense) {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "offense not found"})
		return
	}

	fines, err := c.Fines.GetFinesByOffenseID(offenseID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch fines"})
		return
	}
	if fines == nil {
		fines = []domain.FineInformation{}
	}

	payments := make([]domain.PaymentRecord, 0)
	for _, fine := range fines {
		records, err := c.Payments.FindByFineID(int64(fine.FineID), 1, 20)
		if err != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch payments"})
			return
		}
		payments = append(payments, records...)
	}

	deductions, err := c.Deductions.ListForRequester(ctx.GetString("username"), Unscoped(ctx, ResourceDeductions))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch deductions"})
		return
	}
	offenseDeductions := make([]domain.DeductionInformation, 0)
	for _, item := range deductions {
		if item.OffenseID == offenseID {
			offenseDeductions = append(offenseDeductions, item)
		}
	}

	appeals, err := c.Appeals.GetAppealsByOffenseID(uint(offenseID))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch appeals"})
		return
	}
	if appeals == nil {
		appeals = []domain.AppealManagement{}
	}

	ctx.JSON(http.StatusOK, gin.H{
		"offense":    offense,
		"fines":      fines,
		"payments":   payments,
		"deductions": offenseDeductions,
		"appeals":    appeals,
	})
}

func parsePositiveInt(raw string, fallback int) int {
	value, err := strconv.Atoi(strings.TrimSpace(raw))
	if err != nil || value < 1 {
		return fallback
	}
	return value
}

func nonNilOffenses(items []domain.OffenseInformation) []domain.OffenseInformation {
	if items == nil {
		return []domain.OffenseInformation{}
	}
	return items
}
