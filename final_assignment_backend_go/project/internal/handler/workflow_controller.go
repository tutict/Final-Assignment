package handler

import (
	"errors"
	"final_assignment_backend_go/project/internal/reliability"
	"final_assignment_backend_go/project/internal/service/payment"
	"io"
	"net/http"
	"strconv"
	"strings"
	"unicode/utf8"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service/statemachine"
)

// WorkflowServiceContract 处理器侧的工作流服务契约。
type WorkflowServiceContract interface {
	TriggerOffenseEvent(offenseID int64, event string) (*domain.OffenseInformation, error)
	TriggerPaymentEvent(paymentID int64, event string, idempotencyKey string) (*domain.PaymentRecord, error)
	TriggerAppealEvent(appealID int64, event string, idempotencyKey string, reason string) (*domain.AppealManagement, error)
}

type appealEventRequest struct {
	Reason string `json:"reason"`
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
	if !requireWorkflowRole(ctx) {
		return
	}
	offenseID, err := strconv.ParseInt(ctx.Param("offenseId"), 10, 64)
	if err != nil || offenseID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid offense ID"})
		return
	}
	event := strings.ToUpper(strings.TrimSpace(ctx.Param("event")))
	if !statemachine.IsKnownOffenseEvent(event) {
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
	if !requireWorkflowRole(ctx) {
		return
	}
	paymentID, err := strconv.ParseInt(ctx.Param("paymentId"), 10, 64)
	if err != nil || paymentID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid payment ID"})
		return
	}
	idempotencyKey, ok := requireIdempotencyKey(ctx)
	if !ok {
		return
	}
	event := strings.ToUpper(strings.TrimSpace(ctx.Param("event")))
	if !statemachine.IsKnownPaymentEvent(event) {
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
	if !requireWorkflowRole(ctx) {
		return
	}
	appealID, err := strconv.ParseInt(ctx.Param("appealId"), 10, 64)
	if err != nil || appealID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid appeal ID"})
		return
	}
	idempotencyKey, ok := requireIdempotencyKey(ctx)
	if !ok {
		return
	}
	event := strings.ToUpper(strings.TrimSpace(ctx.Param("event")))
	if !statemachine.IsKnownAppealEvent(event) {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "unknown appeal event: " + event})
		return
	}
	var payload appealEventRequest
	if err := ctx.ShouldBindJSON(&payload); err != nil && !errors.Is(err, io.EOF) {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"errorCode": "VALIDATION_ERROR",
			"message":   "请求体必须是包含 reason 的 JSON 对象",
		})
		return
	}
	reason := strings.TrimSpace(payload.Reason)
	if utf8.RuneCountInString(reason) > 500 {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"errorCode": "VALIDATION_ERROR",
			"message":   "驳回原因不能超过 500 字",
		})
		return
	}
	updated, err := c.Service.TriggerAppealEvent(appealID, event, idempotencyKey, reason)
	if err != nil {
		workflowError(ctx, err)
		return
	}
	ctx.JSON(http.StatusOK, updated)
}

// requireWorkflowRole 对齐 Spring / Cloud / Quarkus WorkflowController 的类级角色。
func requireWorkflowRole(ctx *gin.Context) bool {
	if memberOfRole(ctx, "SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE", "APPEAL_REVIEWER") {
		return true
	}
	ctx.JSON(http.StatusForbidden, gin.H{"error": "access denied"})
	return false
}

// workflowError 对齐 Spring WorkflowController 的错误语义：404 / 208 / 409。
func workflowError(ctx *gin.Context, err error) {
	switch {
	case errors.Is(err, statemachine.ErrWorkflowRecordNotFound),
		errors.Is(err, payment.ErrPaymentNotFound):
		ctx.JSON(http.StatusNotFound, gin.H{"error": "record not found"})
	case errors.Is(err, payment.ErrPaymentDuplicate), errors.Is(err, reliability.ErrReplay):
		ctx.JSON(http.StatusAlreadyReported, apiOK(nil))
	case errors.Is(err, reliability.ErrKeyRequired):
		ctx.JSON(http.StatusBadRequest, gin.H{"errorCode": "MISSING_HEADER", "message": "Missing required header: Idempotency-Key"})
	case errors.Is(err, reliability.ErrConflict):
		reliability.NoteIdempotencyConflict()
		ctx.JSON(http.StatusConflict, gin.H{"errorCode": "IDEMPOTENCY_CONFLICT", "message": err.Error()})
	case errors.Is(err, reliability.ErrInProgress):
		ctx.Header("Retry-After", "1")
		ctx.JSON(http.StatusConflict, gin.H{"errorCode": "IDEMPOTENCY_IN_PROGRESS", "message": err.Error()})
	case errors.Is(err, statemachine.ErrWorkflowTransitionRejected),
		errors.Is(err, payment.ErrPaymentOptimisticLock):
		ctx.JSON(http.StatusConflict, apiError("WORKFLOW_CONFLICT", "该记录已被处理，请刷新页面查看最新状态"))
	default:
		if writeConnectionWait(ctx, err) {
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
	}
}
