package handler

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"
)

// PaymentService 处理器侧的支付记录服务契约。
type PaymentService interface {
	CheckAndInsertIdempotency(string, *domain.PaymentRecord, string) error
	CreatePayment(*domain.PaymentRecord) error
	DeletePayment(int64) error
	FindByDriverID(int64, int, int) ([]domain.PaymentRecord, error)
	FindByFineID(int64, int, int) ([]domain.PaymentRecord, error)
	FindByID(int64) (*domain.PaymentRecord, error)
	GetAllPayments() ([]domain.PaymentRecord, error)
	SearchByPayerIDCard(string, int, int) ([]domain.PaymentRecord, error)
	SearchByPayerName(string, int, int) ([]domain.PaymentRecord, error)
	SearchByPaymentChannel(string, int, int) ([]domain.PaymentRecord, error)
	SearchByPaymentMethod(string, int, int) ([]domain.PaymentRecord, error)
	SearchByPaymentNumber(string, int, int) ([]domain.PaymentRecord, error)
	SearchByPaymentStatus(string, int, int) ([]domain.PaymentRecord, error)
	SearchByPaymentTimeRange(string, string, int, int) ([]domain.PaymentRecord, error)
	SearchByTransactionID(string, int, int) ([]domain.PaymentRecord, error)
	UpdatePayment(*domain.PaymentRecord) error
	UpdatePaymentStatus(int64, string, string) (*domain.PaymentRecord, error)
}

// UserProfileProvider 提供当前登录用户档案（用于驾驶员归属校验）。
type UserProfileProvider interface {
	GetCurrentUserProfile(username string) (map[string]interface{}, error)
}

// PaymentRecordController 对齐 Spring 的 PaymentRecordController（/api/payments）。
type PaymentRecordController struct {
	Service  PaymentService
	Profiles UserProfileProvider
}

func NewPaymentRecordController(payments PaymentService, profiles UserProfileProvider) *PaymentRecordController {
	return &PaymentRecordController{Service: payments, Profiles: profiles}
}

// RegisterRoutes 注册 /api/payments 路由。
func (c *PaymentRecordController) RegisterRoutes(group *gin.RouterGroup) {
	api := group.Group("/payments")

	api.POST("", c.createPayment)
	api.GET("", c.listPayments)
	api.GET("/fine/:fineId", c.findByFine)
	api.GET("/driver/:driverId", c.findByDriver)
	api.POST("/driver/:driverId", c.createDriverPayment)
	api.GET("/search/payer", c.searchByPayer)
	api.GET("/search/status", c.searchByStatus)
	api.GET("/search/transaction", c.searchByTransaction)
	api.GET("/search/payment-number", c.searchByPaymentNumber)
	api.GET("/search/payer-name", c.searchByPayerName)
	api.GET("/search/payment-method", c.searchByPaymentMethod)
	api.GET("/search/payment-channel", c.searchByPaymentChannel)
	api.GET("/search/time-range", c.searchByTimeRange)
	api.PUT("/:paymentId/status/:state", c.updatePaymentStatus)
	api.PUT("/:paymentId", c.updatePayment)
	api.DELETE("/:paymentId", c.deletePayment)
	api.GET("/:paymentId", c.getPayment)
}

// POST /api/payments
func (c *PaymentRecordController) createPayment(ctx *gin.Context) {
	var payment domain.PaymentRecord
	if err := ctx.ShouldBindJSON(&payment); err != nil {
		ctx.JSON(http.StatusBadRequest, apiError("INVALID_REQUEST", err.Error()))
		return
	}
	if err := c.Service.CheckAndInsertIdempotency(idempotencyKeyHeader(ctx), &payment, "create"); err != nil {
		if errors.Is(err, service.ErrPaymentDuplicate) {
			ctx.JSON(http.StatusAlreadyReported, apiOK(nil))
			return
		}
		ctx.JSON(http.StatusInternalServerError, apiError("INTERNAL_ERROR", err.Error()))
		return
	}
	ctx.JSON(http.StatusCreated, apiOK(paymentResponse(&payment)))
}

// PUT /api/payments/:paymentId
func (c *PaymentRecordController) updatePayment(ctx *gin.Context) {
	paymentID, err := strconv.ParseInt(ctx.Param("paymentId"), 10, 64)
	if err != nil || paymentID <= 0 {
		ctx.JSON(http.StatusBadRequest, apiError("INVALID_REQUEST", "paymentId must be a positive integer"))
		return
	}
	var payment domain.PaymentRecord
	if err := ctx.ShouldBindJSON(&payment); err != nil {
		ctx.JSON(http.StatusBadRequest, apiError("INVALID_REQUEST", err.Error()))
		return
	}
	payment.PaymentID = paymentID
	if err := c.Service.CheckAndInsertIdempotency(idempotencyKeyHeader(ctx), &payment, "update"); err != nil {
		switch {
		case errors.Is(err, service.ErrPaymentDuplicate):
			ctx.JSON(http.StatusAlreadyReported, apiOK(nil))
		case errors.Is(err, service.ErrPaymentOptimisticLock):
			ctx.JSON(http.StatusConflict, apiError("PAYMENT_CONFLICT", err.Error()))
		case errors.Is(err, service.ErrPaymentNotFound):
			ctx.JSON(http.StatusNotFound, apiError("PAYMENT_NOT_FOUND", "Payment record not found"))
		default:
			ctx.JSON(http.StatusInternalServerError, apiError("INTERNAL_ERROR", err.Error()))
		}
		return
	}
	ctx.JSON(http.StatusOK, apiOK(paymentResponse(&payment)))
}

// DELETE /api/payments/:paymentId
func (c *PaymentRecordController) deletePayment(ctx *gin.Context) {
	paymentID, err := strconv.ParseInt(ctx.Param("paymentId"), 10, 64)
	if err != nil || paymentID <= 0 {
		ctx.JSON(http.StatusBadRequest, apiError("INVALID_REQUEST", "paymentId must be a positive integer"))
		return
	}
	if err := c.Service.DeletePayment(paymentID); err != nil {
		if errors.Is(err, service.ErrPaymentNotFound) {
			ctx.JSON(http.StatusNotFound, apiError("PAYMENT_NOT_FOUND", "Payment record not found"))
			return
		}
		ctx.JSON(http.StatusInternalServerError, apiError("INTERNAL_ERROR", err.Error()))
		return
	}
	ctx.Status(http.StatusNoContent)
}

// GET /api/payments/:paymentId
func (c *PaymentRecordController) getPayment(ctx *gin.Context) {
	paymentID, err := strconv.ParseInt(ctx.Param("paymentId"), 10, 64)
	if err != nil || paymentID <= 0 {
		ctx.JSON(http.StatusBadRequest, apiError("INVALID_REQUEST", "paymentId must be a positive integer"))
		return
	}
	payment, err := c.Service.FindByID(paymentID)
	if err != nil {
		ctx.JSON(http.StatusNotFound, apiError("PAYMENT_NOT_FOUND", "Payment record not found"))
		return
	}
	ctx.JSON(http.StatusOK, apiOK(paymentResponse(payment)))
}

// GET /api/payments
func (c *PaymentRecordController) listPayments(ctx *gin.Context) {
	payments, err := c.Service.GetAllPayments()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, apiError("INTERNAL_ERROR", "Failed to list payments"))
		return
	}
	ctx.JSON(http.StatusOK, apiOK(paymentResponses(payments)))
}

// GET /api/payments/fine/:fineId
func (c *PaymentRecordController) findByFine(ctx *gin.Context) {
	fineID, err := strconv.ParseInt(ctx.Param("fineId"), 10, 64)
	if err != nil || fineID <= 0 {
		ctx.JSON(http.StatusBadRequest, apiError("INVALID_REQUEST", "fineId must be a positive integer"))
		return
	}
	page, size := paginationParams(ctx)
	payments, err := c.Service.FindByFineID(fineID, page, size)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, apiError("INTERNAL_ERROR", "Failed to list payments"))
		return
	}
	ctx.JSON(http.StatusOK, apiOK(paymentResponses(payments)))
}

// GET /api/payments/driver/:driverId
func (c *PaymentRecordController) findByDriver(ctx *gin.Context) {
	driverID, err := strconv.ParseInt(ctx.Param("driverId"), 10, 64)
	if err != nil || driverID <= 0 {
		ctx.JSON(http.StatusBadRequest, apiError("INVALID_REQUEST", "driverId must be a positive integer"))
		return
	}
	if !c.canAccessDriver(ctx, driverID) {
		ctx.JSON(http.StatusForbidden, apiError("FORBIDDEN", "Forbidden"))
		return
	}
	page, size := paginationParams(ctx)
	payments, err := c.Service.FindByDriverID(driverID, page, size)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, apiError("INTERNAL_ERROR", "Failed to list payments"))
		return
	}
	ctx.JSON(http.StatusOK, apiOK(paymentResponses(payments)))
}

// POST /api/payments/driver/:driverId
func (c *PaymentRecordController) createDriverPayment(ctx *gin.Context) {
	driverID, err := strconv.ParseInt(ctx.Param("driverId"), 10, 64)
	if err != nil || driverID <= 0 {
		ctx.JSON(http.StatusBadRequest, apiError("INVALID_REQUEST", "driverId must be a positive integer"))
		return
	}
	if !c.canAccessDriver(ctx, driverID) {
		ctx.JSON(http.StatusForbidden, apiError("FORBIDDEN", "Forbidden"))
		return
	}
	var payment domain.PaymentRecord
	if err := ctx.ShouldBindJSON(&payment); err != nil {
		ctx.JSON(http.StatusBadRequest, apiError("INVALID_REQUEST", err.Error()))
		return
	}
	payment.DriverID = &driverID
	if err := c.Service.CheckAndInsertIdempotency(idempotencyKeyHeader(ctx), &payment, "create"); err != nil {
		if errors.Is(err, service.ErrPaymentDuplicate) {
			ctx.JSON(http.StatusAlreadyReported, apiOK(nil))
			return
		}
		ctx.JSON(http.StatusInternalServerError, apiError("INTERNAL_ERROR", err.Error()))
		return
	}
	ctx.JSON(http.StatusCreated, apiOK(paymentResponse(&payment)))
}

// GET /api/payments/search/payer?idCard=
func (c *PaymentRecordController) searchByPayer(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	payments, err := c.Service.SearchByPayerIDCard(ctx.Query("idCard"), page, size)
	searchResult(ctx, payments, err)
}

// GET /api/payments/search/status?status=
func (c *PaymentRecordController) searchByStatus(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	payments, err := c.Service.SearchByPaymentStatus(ctx.Query("status"), page, size)
	searchResult(ctx, payments, err)
}

// GET /api/payments/search/transaction?transactionId=
func (c *PaymentRecordController) searchByTransaction(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	payments, err := c.Service.SearchByTransactionID(ctx.Query("transactionId"), page, size)
	searchResult(ctx, payments, err)
}

// GET /api/payments/search/payment-number?paymentNumber=
func (c *PaymentRecordController) searchByPaymentNumber(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	payments, err := c.Service.SearchByPaymentNumber(ctx.Query("paymentNumber"), page, size)
	searchResult(ctx, payments, err)
}

// GET /api/payments/search/payer-name?payerName=
func (c *PaymentRecordController) searchByPayerName(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	payments, err := c.Service.SearchByPayerName(ctx.Query("payerName"), page, size)
	searchResult(ctx, payments, err)
}

// GET /api/payments/search/payment-method?paymentMethod=
func (c *PaymentRecordController) searchByPaymentMethod(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	payments, err := c.Service.SearchByPaymentMethod(ctx.Query("paymentMethod"), page, size)
	searchResult(ctx, payments, err)
}

// GET /api/payments/search/payment-channel?paymentChannel=
func (c *PaymentRecordController) searchByPaymentChannel(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	payments, err := c.Service.SearchByPaymentChannel(ctx.Query("paymentChannel"), page, size)
	searchResult(ctx, payments, err)
}

// GET /api/payments/search/time-range?startTime=&endTime=
func (c *PaymentRecordController) searchByTimeRange(ctx *gin.Context) {
	page, size := paginationParams(ctx)
	payments, err := c.Service.SearchByPaymentTimeRange(ctx.Query("startTime"), ctx.Query("endTime"), page, size)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, apiError("INVALID_REQUEST", err.Error()))
		return
	}
	ctx.JSON(http.StatusOK, apiOK(paymentResponses(payments)))
}

// PUT /api/payments/:paymentId/status/:state
func (c *PaymentRecordController) updatePaymentStatus(ctx *gin.Context) {
	paymentID, err := strconv.ParseInt(ctx.Param("paymentId"), 10, 64)
	if err != nil || paymentID <= 0 {
		ctx.JSON(http.StatusBadRequest, apiError("INVALID_REQUEST", "paymentId must be a positive integer"))
		return
	}
	idempotencyKey := idempotencyKeyHeader(ctx)
	if idempotencyKey == "" {
		ctx.JSON(http.StatusBadRequest, apiError("INVALID_REQUEST", "Idempotency-Key header is required"))
		return
	}
	state := ctx.Param("state")
	status := resolvePaymentStateParam(state)
	if status == "" {
		ctx.JSON(http.StatusBadRequest, apiError("INVALID_REQUEST", "unknown payment state: "+state))
		return
	}
	if _, err := c.Service.UpdatePaymentStatus(paymentID, status, idempotencyKey); err != nil {
		switch {
		case errors.Is(err, service.ErrPaymentDuplicate):
			ctx.JSON(http.StatusAlreadyReported, apiOK(nil))
		case errors.Is(err, service.ErrPaymentOptimisticLock):
			ctx.JSON(http.StatusConflict, apiError("PAYMENT_CONFLICT", err.Error()))
		case errors.Is(err, service.ErrPaymentNotFound):
			ctx.JSON(http.StatusNotFound, apiError("PAYMENT_NOT_FOUND", "Payment record not found"))
		default:
			ctx.JSON(http.StatusInternalServerError, apiError("INTERNAL_ERROR", err.Error()))
		}
		return
	}
	ctx.JSON(http.StatusOK, apiOK(nil))
}

// canAccessDriver 对齐 Spring 的 PaymentRecordController.canAccessDriver：
// 高权限角色直接放行，普通用户仅能访问本人 driverId。
func (c *PaymentRecordController) canAccessDriver(ctx *gin.Context, driverID int64) bool {
	if memberOfRole(ctx, "SUPER_ADMIN", "ADMIN", "FINANCE") {
		return true
	}
	if !memberOfRole(ctx, "USER") {
		return false
	}
	profile, err := c.Profiles.GetCurrentUserProfile(ctx.GetString("username"))
	if err != nil {
		return false
	}
	switch value := profile["driverId"].(type) {
	case int:
		return int64(value) == driverID
	case int64:
		return value == driverID
	default:
		return false
	}
}

// resolvePaymentStateParam 将路径参数解析为状态 code，未知状态返回空串。
func resolvePaymentStateParam(state string) string {
	switch state {
	case "Unpaid", "unpaid", "UNPAID":
		return service.PaymentStateUnpaid
	case "Partial", "partial", "PARTIAL":
		return service.PaymentStatePartial
	case "Paid", "paid", "PAID":
		return service.PaymentStatePaid
	case "Overdue", "overdue", "OVERDUE":
		return service.PaymentStateOverdue
	case "Waived", "waived", "WAIVED":
		return service.PaymentStateWaived
	default:
		return ""
	}
}

// paymentResponse 对齐 Spring 的 PaymentRecordResponse（剔除密文列）。
func paymentResponse(payment *domain.PaymentRecord) map[string]any {
	return map[string]any{
		"paymentId":      payment.PaymentID,
		"fineId":         payment.FineID,
		"driverId":       payment.DriverID,
		"paymentNumber":  payment.PaymentNumber,
		"paymentAmount":  payment.PaymentAmount,
		"paymentMethod":  payment.PaymentMethod,
		"paymentTime":    payment.PaymentTime,
		"paymentChannel": payment.PaymentChannel,
		"payerName":      payment.PayerName,
		"payerIdCard":    payment.PayerIDCard,
		"payerContact":   payment.PayerContact,
		"bankName":       payment.BankName,
		"bankAccount":    payment.BankAccount,
		"transactionId":  payment.TransactionID,
		"receiptNumber":  payment.ReceiptNumber,
		"receiptUrl":     payment.ReceiptURL,
		"paymentStatus":  payment.PaymentStatus,
		"refundAmount":   payment.RefundAmount,
		"refundTime":     payment.RefundTime,
		"createdAt":      payment.CreatedAt,
		"updatedAt":      payment.UpdatedAt,
		"remarks":        payment.Remarks,
	}
}

func paymentResponses(payments []domain.PaymentRecord) []map[string]any {
	result := make([]map[string]any, 0, len(payments))
	for i := range payments {
		result = append(result, paymentResponse(&payments[i]))
	}
	return result
}

// idempotencyKeyHeader 读取 Idempotency-Key 请求头（回退查询参数以兼容 Go 后端惯例）。
func idempotencyKeyHeader(ctx *gin.Context) string {
	if key := ctx.GetHeader("Idempotency-Key"); key != "" {
		return key
	}
	return ctx.Query("idempotencyKey")
}

// paginationParams 解析分页参数，缺省 1 / 20，与 Spring 保持一致。
func paginationParams(ctx *gin.Context) (int, int) {
	page, err := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	if err != nil || page < 1 {
		page = 1
	}
	size, err := strconv.Atoi(ctx.DefaultQuery("size", "20"))
	if err != nil || size < 1 {
		size = 20
	}
	return page, size
}

func searchResult(ctx *gin.Context, payments []domain.PaymentRecord, err error) {
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, apiError("INTERNAL_ERROR", "Failed to search payments"))
		return
	}
	ctx.JSON(http.StatusOK, apiOK(paymentResponses(payments)))
}
