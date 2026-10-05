package handler

import (
	"database/sql"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type FeedbackController struct {
	DB *gorm.DB
}

func NewFeedbackController(db *gorm.DB) *FeedbackController {
	return &FeedbackController{DB: db}
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
	query := `SELECT feedback_id, username, feedback_type, content, contact, status, created_at
		FROM consultation_feedback`
	args := []any{}
	if !isStaff(ctx) {
		query += " WHERE username = ?"
		args = append(args, username)
	}
	query += " ORDER BY feedback_id DESC"
	rows, err := c.DB.Raw(query, args...).Rows()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"errorCode": "INTERNAL_ERROR", "message": err.Error()})
		return
	}
	defer rows.Close()
	items := make([]gin.H, 0)
	for rows.Next() {
		item, err := scanFeedback(rows)
		if err != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"errorCode": "INTERNAL_ERROR", "message": err.Error()})
			return
		}
		items = append(items, item)
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
	key := strings.TrimSpace(ctx.GetHeader("Idempotency-Key"))
	if key != "" {
		row := c.DB.Raw(`SELECT feedback_id, username, feedback_type, content, contact, status, created_at
			FROM consultation_feedback WHERE idempotency_key = ?`, key).Row()
		item, err := scanFeedbackRow(row)
		if err == nil {
			ctx.JSON(http.StatusOK, item)
			return
		}
	}
	content := firstText(body, "content", "feedback")
	if strings.TrimSpace(content) == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"errorCode": "INVALID_ARGUMENT", "message": "反馈内容不能为空"})
		return
	}
	if len([]rune(content)) > 2000 {
		ctx.JSON(http.StatusBadRequest, gin.H{"errorCode": "INVALID_ARGUMENT", "message": "反馈内容过长"})
		return
	}
	kind := firstText(body, "feedbackType", "type")
	if kind == "" {
		kind = "咨询"
	}
	contact := firstText(body, "contact")
	status := "Pending"
	if isStaff(ctx) {
		if requested := firstText(body, "status"); requested != "" {
			status = requested
		}
	}
	created := time.Now()
	tx := c.DB.Begin()
	if tx.Error != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"errorCode": "INTERNAL_ERROR", "message": tx.Error.Error()})
		return
	}
	if err := tx.Exec(`INSERT INTO consultation_feedback
		(username, feedback_type, content, contact, status, idempotency_key, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?)`,
		username, kind, content, blankToNil(contact), status, blankToNil(key), created).Error; err != nil {
		tx.Rollback()
		ctx.JSON(http.StatusInternalServerError, gin.H{"errorCode": "INTERNAL_ERROR", "message": err.Error()})
		return
	}
	var id int64
	if err := tx.Raw("SELECT LAST_INSERT_ID()").Scan(&id).Error; err != nil {
		tx.Rollback()
		ctx.JSON(http.StatusInternalServerError, gin.H{"errorCode": "INTERNAL_ERROR", "message": err.Error()})
		return
	}
	if err := tx.Commit().Error; err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"errorCode": "INTERNAL_ERROR", "message": err.Error()})
		return
	}
	ctx.JSON(http.StatusCreated, feedbackJSON(id, username, kind, content, contact, status, created))
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
	row := c.DB.Raw(`SELECT feedback_id, username, feedback_type, content, contact, status, created_at
		FROM consultation_feedback WHERE feedback_id = ?`, id).Row()
	current, err := scanFeedbackRow(row)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"errorCode": "NOT_FOUND", "message": "Feedback not found"})
		return
	}
	if !isStaff(ctx) && current["username"] != username {
		ctx.JSON(http.StatusForbidden, gin.H{"errorCode": "FORBIDDEN", "message": "Forbidden"})
		return
	}
	var body map[string]any
	_ = ctx.ShouldBindJSON(&body)
	content := firstText(body, "content", "feedback")
	if content == "" {
		content = asString(current["content"])
	}
	kind := firstText(body, "feedbackType")
	if kind == "" {
		kind = asString(current["feedbackType"])
	}
	contact := asString(current["contact"])
	if _, present := body["contact"]; present {
		contact = firstText(body, "contact")
	}
	status := asString(current["status"])
	if isStaff(ctx) && firstText(body, "status") != "" {
		status = firstText(body, "status")
	}
	if err := c.DB.Exec(`UPDATE consultation_feedback
		SET feedback_type = ?, content = ?, contact = ?, status = ?
		WHERE feedback_id = ?`, kind, content, blankToNil(contact), status, id).Error; err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"errorCode": "INTERNAL_ERROR", "message": err.Error()})
		return
	}
	current["feedbackType"] = kind
	current["content"] = content
	current["feedback"] = content
	current["contact"] = contact
	current["status"] = status
	ctx.JSON(http.StatusOK, current)
}

func currentUsername(ctx *gin.Context) (string, bool) {
	value, _ := ctx.Get("username")
	username := strings.TrimSpace(asString(value))
	return username, username != ""
}

func isStaff(ctx *gin.Context) bool {
	roles, _ := ctx.Get("roles")
	switch typed := roles.(type) {
	case []string:
		for _, role := range typed {
			if strings.Contains(role, "ADMIN") || strings.Contains(role, "STAFF") {
				return true
			}
		}
	case string:
		return strings.Contains(typed, "ADMIN") || strings.Contains(typed, "STAFF")
	}
	return false
}

func firstText(body map[string]any, keys ...string) string {
	for _, key := range keys {
		if value, ok := body[key]; ok {
			text := strings.TrimSpace(asString(value))
			if text != "" {
				return text
			}
		}
	}
	return ""
}

func asString(value any) string {
	switch typed := value.(type) {
	case string:
		return typed
	case nil:
		return ""
	default:
		return ""
	}
}

func blankToNil(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}
	return strings.TrimSpace(value)
}

type feedbackScanner interface {
	Scan(dest ...any) error
}

func scanFeedback(rows *sql.Rows) (gin.H, error) {
	return scanFeedbackValues(rows)
}

func scanFeedbackRow(row *sql.Row) (gin.H, error) {
	return scanFeedbackValues(row)
}

func scanFeedbackValues(scanner feedbackScanner) (gin.H, error) {
	var id int64
	var username, kind, content, status string
	var contact sql.NullString
	var created time.Time
	if err := scanner.Scan(&id, &username, &kind, &content, &contact, &status, &created); err != nil {
		return nil, err
	}
	contactText := ""
	if contact.Valid {
		contactText = contact.String
	}
	return feedbackJSON(id, username, kind, content, contactText, status, created), nil
}

func feedbackJSON(id int64, username, kind, content, contact, status string, created time.Time) gin.H {
	return gin.H{
		"feedbackId":   id,
		"username":     username,
		"feedbackType": kind,
		"content":      content,
		"feedback":     content,
		"contact":      contact,
		"status":       status,
		"timestamp":    created.Format("2006-01-02T15:04:05"),
	}
}
