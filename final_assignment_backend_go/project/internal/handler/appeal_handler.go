package handler

import (
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
)

// AppealHandler 对应 Java 的 AppealManagementController
type AppealHandler struct {
	appealService AppealService
}

// NewAppealHandler 构造函数
func NewAppealHandler(appealService AppealService) *AppealHandler {
	return &AppealHandler{appealService}
}

// CreateAppeal 创建新申诉（POST /api/appeals）
func (h *AppealHandler) CreateAppeal(c *gin.Context) {
	var appeal domain.AppealManagement
	idempotencyKey, ok := requireIdempotencyKey(c)
	if !ok {
		return
	}

	if err := c.ShouldBindJSON(&appeal); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	created, err := h.appealService.CheckAndInsertIdempotency(idempotencyKey, &appeal, "create")
	if err != nil {
		log.Printf("Error creating appeal: %v", err)
		writeLedgerError(c, err)
		return
	}
	c.JSON(http.StatusCreated, created)
}

// GetMyAppeals 当前用户自己的申诉（GET /api/appeals/my）。
// 必须注册在 /:id 之前，否则 gin 会把 "my" 当成 appeal ID。
func (h *AppealHandler) GetMyAppeals(c *gin.Context) {
	appeals, err := h.appealService.ListForRequester(c.GetString("username"), Unscoped(c, ResourceAppeals))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if appeals == nil {
		appeals = []domain.AppealManagement{}
	}
	c.JSON(http.StatusOK, appeals)
}

// GetAppealByID 获取单个申诉（GET /api/appeals/:id）
func (h *AppealHandler) GetAppealByID(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid appeal ID"})
		return
	}

	appeal, err := h.appealService.GetAppealByID(uint(id))
	if err != nil || !h.appealService.CanAccess(c.GetString("username"), Unscoped(c, ResourceAppeals), appeal) {
		c.JSON(http.StatusNotFound, gin.H{"error": "appeal not found"})
		return
	}
	c.JSON(http.StatusOK, appeal)
}

// GetAllAppeals 获取所有申诉（GET /api/appeals）
func (h *AppealHandler) GetAllAppeals(c *gin.Context) {
	appeals, err := h.appealService.ListForRequester(c.GetString("username"), Unscoped(c, ResourceAppeals))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, appeals)
}

// UpdateAppeal 更新申诉（PUT /api/appeals/:id）
func (h *AppealHandler) UpdateAppeal(c *gin.Context) {
	if !RequireWrite(c, ResourceAppeals) {
		return
	}
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid appeal ID"})
		return
	}

	var updated domain.AppealManagement
	idempotencyKey, ok := requireIdempotencyKey(c)
	if !ok {
		return
	}

	if err := c.ShouldBindJSON(&updated); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	updated.AppealID = int(uint(id))
	appeal, err := h.appealService.CheckAndInsertIdempotency(idempotencyKey, &updated, "update")
	if err != nil {
		writeLedgerError(c, err)
		return
	}
	c.JSON(http.StatusOK, appeal)
}

// DeleteAppeal 删除申诉（DELETE /api/appeals/:id）
func (h *AppealHandler) DeleteAppeal(c *gin.Context) {
	if !RequireWrite(c, ResourceAppeals) {
		return
	}
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid appeal ID"})
		return
	}

	if err := h.appealService.DeleteAppeal(uint(id)); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

// GetAppealsByProcessStatus 按状态查询（GET /api/appeals/status/:status）
func (h *AppealHandler) GetAppealsByProcessStatus(c *gin.Context) {
	status := c.Param("status")
	appeals, err := h.appealService.GetAppealsByProcessStatus(status)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, h.appealService.FilterForRequester(c.GetString("username"), Unscoped(c, ResourceAppeals), appeals))
}

// GetAppealsByAppellantName 按姓名查询（GET /api/appeals/name/:name）
func (h *AppealHandler) GetAppealsByAppellantName(c *gin.Context) {
	name := c.Param("name")
	appeals, err := h.appealService.GetAppealsByAppellantName(name)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, h.appealService.FilterForRequester(c.GetString("username"), Unscoped(c, ResourceAppeals), appeals))
}

// GetOffenseByAppealID 获取申诉关联违章信息（GET /api/appeals/:id/offense）
func (h *AppealHandler) GetOffenseByAppealID(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid appeal ID"})
		return
	}

	appeal, aerr := h.appealService.GetAppealByID(uint(id))
	if aerr != nil || !h.appealService.CanAccess(c.GetString("username"), Unscoped(c, ResourceAppeals), appeal) {
		c.JSON(http.StatusNotFound, gin.H{"error": "appeal not found"})
		return
	}
	offense, err := h.appealService.GetOffenseByAppealID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, offense)
}

// GetAppealsByIdCardNumber 按身份证号查询（GET /api/appeals/id-card/:idCard）
func (h *AppealHandler) GetAppealsByIdCardNumber(c *gin.Context) {
	idCard := c.Param("idCard")
	appeals, err := h.appealService.GetAppealsByIdCardNumber(idCard)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, h.appealService.FilterForRequester(c.GetString("username"), Unscoped(c, ResourceAppeals), appeals))
}

// GetAppealsByContactNumber 按联系电话查询（GET /api/appeals/contact/:number）
func (h *AppealHandler) GetAppealsByContactNumber(c *gin.Context) {
	contact := c.Param("number")
	appeals, err := h.appealService.GetAppealsByContactNumber(contact)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, h.appealService.FilterForRequester(c.GetString("username"), Unscoped(c, ResourceAppeals), appeals))
}

// GetAppealsByOffenseID 按违章ID查询（GET /api/appeals/offense/:offenseId）
func (h *AppealHandler) GetAppealsByOffenseID(c *gin.Context) {
	offenseID, err := strconv.Atoi(c.Param("offenseId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid offense ID"})
		return
	}

	appeals, err := h.appealService.GetAppealsByOffenseID(uint(offenseID))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, h.appealService.FilterForRequester(c.GetString("username"), Unscoped(c, ResourceAppeals), appeals))
}

// GetAppealsByTimeRange 按时间范围查询（GET /api/appeals/time-range?start=...&end=...）
func (h *AppealHandler) GetAppealsByTimeRange(c *gin.Context) {
	startStr := c.Query("start")
	endStr := c.Query("end")

	start, err1 := time.Parse(time.RFC3339, startStr)
	end, err2 := time.Parse(time.RFC3339, endStr)
	if err1 != nil || err2 != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid time format"})
		return
	}

	appeals, err := h.appealService.GetAppealsByTimeRange(start, end)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, h.appealService.FilterForRequester(c.GetString("username"), Unscoped(c, ResourceAppeals), appeals))
}

// CountAppealsByStatus 按状态统计数量（GET /api/appeals/count/status/:status）
func (h *AppealHandler) CountAppealsByStatus(c *gin.Context) {
	status := c.Param("status")
	count, err := h.appealService.CountAppealsByStatus(status)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"count": count})
}
func (h *AppealHandler) CreateReview(c *gin.Context) {
	if !RequireWrite(c, ResourceAppeals) {
		return
	}
	appealID, err := strconv.Atoi(c.Param("id"))
	if err != nil || appealID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid appeal ID"})
		return
	}
	key, ok := requireIdempotencyKey(c)
	if !ok {
		return
	}
	var review domain.AppealReview
	if err := c.ShouldBindJSON(&review); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}
	saved, err := h.appealService.CreateAppealReview(appealID, key, &review)
	if err != nil {
		writeLedgerError(c, err)
		return
	}
	c.JSON(http.StatusCreated, saved)
}


func (h *AppealHandler) RegisterSearchRoutes(group *gin.RouterGroup) {
	group.GET("/search/number/prefix", h.SearchAppealsByNumberPrefix)
	group.GET("/search/number/fuzzy", h.SearchAppealsByNumberFuzzy)
	group.GET("/search/appellant/name/prefix", h.SearchAppealsByNamePrefix)
	group.GET("/search/appellant/name/fuzzy", h.SearchAppealsByNameFuzzy)
	group.GET("/search/appellant/id-card", h.SearchAppealsByIdCard)
	group.GET("/search/acceptance-status", h.SearchAppealsByAcceptanceStatus)
	group.GET("/search/process-status", h.SearchAppealsByProcessStatus)
	group.GET("/search/time-range", h.SearchAppealsByTimeRange)
	group.GET("/search/handler", h.SearchAppealsByHandler)
	group.GET("/reviews/search/reviewer", h.SearchReviewsByReviewer)
	group.GET("/reviews/search/reviewer-dept", h.SearchReviewsByDept)
	group.GET("/reviews/search/time-range", h.SearchReviewsByTime)
	group.GET("/reviews/count", h.CountReviews)
	group.GET("/reviews", h.ListReviews)
	group.GET("/reviews/:reviewId", h.GetReview)
	group.PUT("/reviews/:reviewId", h.UpdateReview)
	group.DELETE("/reviews/:reviewId", h.DeleteReview)
}

func (h *AppealHandler) SearchAppealsByNumberPrefix(c *gin.Context) {
	query := c.Query("appealNumber")
	h.searchAppeals(c, func(item domain.AppealManagement) bool {
		return hasPrefixFold(item.AppealNumber, query)
	})
}

func (h *AppealHandler) SearchAppealsByNumberFuzzy(c *gin.Context) {
	query := c.Query("appealNumber")
	h.searchAppeals(c, func(item domain.AppealManagement) bool {
		return containsFold(item.AppealNumber, query)
	})
}

func (h *AppealHandler) SearchAppealsByNamePrefix(c *gin.Context) {
	query := c.Query("appellantName")
	h.searchAppeals(c, func(item domain.AppealManagement) bool {
		return hasPrefixFold(item.AppellantName, query)
	})
}

func (h *AppealHandler) SearchAppealsByNameFuzzy(c *gin.Context) {
	query := c.Query("appellantName")
	h.searchAppeals(c, func(item domain.AppealManagement) bool {
		return containsFold(item.AppellantName, query)
	})
}

func (h *AppealHandler) SearchAppealsByIdCard(c *gin.Context) {
	query := c.Query("appellantIdCard")
	h.searchAppeals(c, func(item domain.AppealManagement) bool {
		return containsFold(item.AppellantIDCard, query)
	})
}

func (h *AppealHandler) SearchAppealsByAcceptanceStatus(c *gin.Context) {
	status := c.Query("acceptanceStatus")
	h.searchAppeals(c, func(item domain.AppealManagement) bool {
		return strings.EqualFold(item.AcceptanceStatus, status)
	})
}

func (h *AppealHandler) SearchAppealsByProcessStatus(c *gin.Context) {
	status := c.Query("processStatus")
	h.searchAppeals(c, func(item domain.AppealManagement) bool {
		return strings.EqualFold(item.ProcessStatus, status)
	})
}

func (h *AppealHandler) SearchAppealsByHandler(c *gin.Context) {
	query := c.Query("acceptanceHandler")
	h.searchAppeals(c, func(item domain.AppealManagement) bool {
		return containsFold(item.AcceptanceHandler, query) || containsFold(item.ProcessHandler, query)
	})
}

func (h *AppealHandler) SearchAppealsByTimeRange(c *gin.Context) {
	start, err1 := parseFlexibleTime(c.DefaultQuery("startTime", "1970-01-01"))
	endRaw := c.DefaultQuery("endTime", "2100-01-01")
	end, err2 := parseFlexibleTime(endRaw)
	if err1 != nil || err2 != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid time format"})
		return
	}
	if len(strings.TrimSpace(endRaw)) == 10 {
		end = end.Add(24*time.Hour - time.Second)
	}
	h.searchAppeals(c, func(item domain.AppealManagement) bool {
		return !item.AppealTime.Before(start) && !item.AppealTime.After(end)
	})
}

func (h *AppealHandler) searchAppeals(c *gin.Context, match func(domain.AppealManagement) bool) {
	appeals, err := h.appealService.ListForRequester(c.GetString("username"), Unscoped(c, ResourceAppeals))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch appeals"})
		return
	}
	filtered := make([]domain.AppealManagement, 0)
	for _, item := range appeals {
		if match(item) {
			filtered = append(filtered, item)
		}
	}
	c.JSON(http.StatusOK, filtered)
}

func hasPrefixFold(value, query string) bool {
	query = strings.TrimSpace(query)
	if query == "" {
		return true
	}
	return strings.HasPrefix(strings.ToLower(value), strings.ToLower(query))
}

func (h *AppealHandler) ListReviews(c *gin.Context) {
	rows, err := h.appealService.ListAppealReviews()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch reviews"})
		return
	}
	c.JSON(http.StatusOK, rows)
}

func (h *AppealHandler) GetReview(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("reviewId"))
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid review id"})
		return
	}
	rows, err := h.appealService.ListAppealReviews()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch reviews"})
		return
	}
	for _, row := range rows {
		if row.ReviewID == id {
			c.JSON(http.StatusOK, row)
			return
		}
	}
	c.JSON(http.StatusNotFound, gin.H{"error": "review not found"})
}

func (h *AppealHandler) CountReviews(c *gin.Context) {
	level := c.Query("level")
	rows, err := h.appealService.ListAppealReviews()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch reviews"})
		return
	}
	count := 0
	for _, row := range rows {
		if strings.EqualFold(row.ReviewLevel, level) {
			count++
		}
	}
	c.JSON(http.StatusOK, gin.H{"count": count})
}

func (h *AppealHandler) SearchReviewsByReviewer(c *gin.Context) {
	query := c.Query("reviewer")
	h.searchReviews(c, func(row domain.AppealReview) bool { return containsFold(row.Reviewer, query) })
}

func (h *AppealHandler) SearchReviewsByDept(c *gin.Context) {
	query := c.Query("reviewerDept")
	h.searchReviews(c, func(row domain.AppealReview) bool { return containsFold(row.ReviewerDept, query) })
}

func (h *AppealHandler) SearchReviewsByTime(c *gin.Context) {
	start, end, err := queryTimeWindow(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid time format"})
		return
	}
	h.searchReviews(c, func(row domain.AppealReview) bool {
		return !row.ReviewTime.Before(start) && !row.ReviewTime.After(end)
	})
}

func (h *AppealHandler) searchReviews(c *gin.Context, match func(domain.AppealReview) bool) {
	rows, err := h.appealService.ListAppealReviews()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch reviews"})
		return
	}
	filtered := make([]domain.AppealReview, 0)
	for _, row := range rows {
		if match(row) {
			filtered = append(filtered, row)
		}
	}
	c.JSON(http.StatusOK, filtered)
}

func (h *AppealHandler) UpdateReview(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("reviewId"))
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid review id"})
		return
	}
	var review domain.AppealReview
	if err := c.ShouldBindJSON(&review); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}
	review.ReviewID = id
	saved, err := h.appealService.UpdateAppealReview(&review)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "review not found"})
		return
	}
	c.JSON(http.StatusOK, saved)
}

func (h *AppealHandler) DeleteReview(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("reviewId"))
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid review id"})
		return
	}
	if err := h.appealService.DeleteAppealReview(id); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "review not found"})
		return
	}
	c.Status(http.StatusNoContent)
}
