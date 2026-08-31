package handler

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"
)

// WorkflowServiceContract 处理器侧的工作流服务契约。
type WorkflowServiceContract interface {
	TriggerOffenseEvent(offenseID int64, event string) (*domain.OffenseInformation, error)
	TriggerPaymentEvent(paymentID int64, event string, idempotencyKey string) (*domain.PaymentRecord, error)
	TriggerAppealEvent(appealID int64, event string) (*domain.AppealManagement, error)
}

// WorkflowController 对齐 Spring 的 WorkflowController（/api/workflow）。
type WorkflowController struct {
	Service WorkflowServiceContract
}

func NewWorkflowController(workflow WorkflowServiceContract) *WorkflowController {
	return &WorkflowController{Service: workflow}
}

// RegisterRoutes 注册 /api/workflow 路由。
func (c *WorkflowController) RegisterRoutes(group *gin.RouterGroup) {
	api := group.Group("/workflow")

	api.POST("/offenses/:offenseId/events/:event", c.triggerOffenseEvent)
	api.POST("/payments/:paymentId/events/:event", c.triggerPaymentEvent)
	api.POST("/appeals/:appealId/events/:event", c.triggerAppealEvent)
}

// POST /api/workflow/offenses/:offenseId/events/:event
func (c *WorkflowController) triggerOffenseEvent(ctx *gin.Context) {
	offenseID, err := strconv.ParseInt(ctx.Param("offenseId"), 10, 64)
	if err != nil || offenseID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid offense ID"})
		return
	}
	event := strings.ToUpper(strings.TrimSpace(ctx.Param("event")))
	if !service.IsKnownOffenseEvent(event) {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "unknown offense event: " + event})
		return
	}
	updated, err := c.Service.TriggerOffenseEvent(offenseID, event)
	if err != nil {
		workflowError(ctx, err)
		return
	}
	ctx.JSON(http.StatusOK, updated)
}

// POST /api/workflow/payments/:paymentId/events/:event
func (c *WorkflowController) triggerPaymentEvent(ctx *gin.Context) {
	paymentID, err := strconv.ParseInt(ctx.Param("paymentId"), 10, 64)
	if err != nil || paymentID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid payment ID"})
		return
	}
	idempotencyKey := idempotencyKeyHeader(ctx)
	if idempotencyKey == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Idempotency-Key header is required"})
		return
	}
	event := strings.ToUpper(strings.TrimSpace(ctx.Param("event")))
	if !service.IsKnownPaymentEvent(event) {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "unknown payment event: " + event})
		return
	}
	updated, err := c.Service.TriggerPaymentEvent(paymentID, event, idempotencyKey)
	if err != nil {
		workflowError(ctx, err)
		return
	}
	ctx.JSON(http.StatusOK, updated)
}

// POST /api/workflow/appeals/:appealId/events/:event
func (c *WorkflowController) triggerAppealEvent(ctx *gin.Context) {
	appealID, err := strconv.ParseInt(ctx.Param("appealId"), 10, 64)
	if err != nil || appealID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid appeal ID"})
		return
	}
	event := strings.ToUpper(strings.TrimSpace(ctx.Param("event")))
	if !service.IsKnownAppealEvent(event) {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "unknown appeal event: " + event})
		return
	}
	updated, err := c.Service.TriggerAppealEvent(appealID, event)
	if err != nil {
		workflowError(ctx, err)
		return
	}
	ctx.JSON(http.StatusOK, updated)
}

// workflowError 对齐 Spring WorkflowController 的错误语义：404 / 208 / 409。
func workflowError(ctx *gin.Context, err error) {
	switch {
	case errors.Is(err, service.ErrWorkflowRecordNotFound),
		errors.Is(err, service.ErrPaymentNotFound):
		ctx.JSON(http.StatusNotFound, gin.H{"error": "record not found"})
	case errors.Is(err, service.ErrPaymentDuplicate):
		ctx.JSON(http.StatusAlreadyReported, apiOK(nil))
	case errors.Is(err, service.ErrWorkflowTransitionRejected),
		errors.Is(err, service.ErrPaymentOptimisticLock):
		ctx.JSON(http.StatusConflict, apiError("WORKFLOW_CONFLICT", "该记录已被处理，请刷新页面查看最新状态"))
	default:
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
	}
}
