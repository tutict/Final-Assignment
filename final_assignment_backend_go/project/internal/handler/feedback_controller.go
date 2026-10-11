package handler

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"final_assignment_backend_go/project/internal/service/business"

	"github.com/gin-gonic/gin"
)

type FeedbackController struct {
	feedback *business.ConsultationFeedbackService
}

func NewFeedbackController(feedback *business.ConsultationFeedbackService) *FeedbackController {
	return &FeedbackController{feedback: feedback}
}

func (c *FeedbackController) RegisterRoutes(router *gin.Engine) {
	group := router.Group("/api/feedback")
	group.GET("", c.list)
	group.POST("", c.create)
	group.PUT("/:feedbackId", c.update)
}

func (c *FeedbackController) list(ctx *gin.Context) {
	username, ok := currentUsername(ctx)
	if !ok {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	items, err := c.feedback.List(username, isStaff(ctx))
	if err != nil {
		writeFeedbackResult(ctx, nil, false, err)
		return
	}
	ctx.JSON(http.StatusOK, items)
}

func (c *FeedbackController) create(ctx *gin.Context) {
	username, ok := currentUsername(ctx)
	if !ok {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	var body map[string]any
	if err := ctx.ShouldBindJSON(&body); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"errorCode": "INVALID_ARGUMENT", "message": "invalid request body"})
		return
	}
	item, created, err := c.feedback.Create(username, isStaff(ctx), body, ctx.GetHeader("Idempotency-Key"))
	writeFeedbackResult(ctx, item, created, err)
}

func (c *FeedbackController) update(ctx *gin.Context) {
	username, ok := currentUsername(ctx)
	if !ok {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	id, err := strconv.ParseInt(ctx.Param("feedbackId"), 10, 64)
	if err != nil || id <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"errorCode": "INVALID_ARGUMENT", "message": "invalid feedback id"})
		return
	}
	var body map[string]any
	if err := ctx.ShouldBindJSON(&body); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"errorCode": "INVALID_ARGUMENT", "message": "invalid request body"})
		return
	}
	item, err := c.feedback.Update(username, isStaff(ctx), id, body)
	if err != nil {
		writeFeedbackResult(ctx, nil, false, err)
		return
	}
	ctx.JSON(http.StatusOK, item)
}

func writeFeedbackResult(ctx *gin.Context, item map[string]any, created bool, err error) {
	if err == nil {
		status := http.StatusOK
		if created {
			status = http.StatusCreated
		}
		ctx.JSON(status, item)
		return
	}
	var feedbackErr *business.FeedbackError
	if errors.As(err, &feedbackErr) {
		ctx.JSON(feedbackErr.Status, gin.H{"errorCode": feedbackErr.Code, "message": feedbackErr.Message})
		return
	}
	ctx.JSON(http.StatusInternalServerError, gin.H{"errorCode": "INTERNAL_ERROR", "message": "internal error"})
}

func currentUsername(ctx *gin.Context) (string, bool) {
	value, _ := ctx.Get("username")
	username, _ := value.(string)
	username = strings.TrimSpace(username)
	return username, username != ""
}

func isStaff(ctx *gin.Context) bool {
	roles, _ := ctx.Get("roles")
	switch typed := roles.(type) {
	case []string:
		for _, role := range typed {
			if business.IsStaffRole(role) {
				return true
			}
		}
	case string:
		return business.IsStaffRole(typed)
	}
	return false
}
