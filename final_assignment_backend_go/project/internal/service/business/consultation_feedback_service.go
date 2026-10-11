package business

import (
	"database/sql"
	"errors"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/go-sql-driver/mysql"
	"gorm.io/gorm"
)

const maxFeedbackContent = 2000
const maxFeedbackKey = 128

const ensureFeedbackTable = `
CREATE TABLE IF NOT EXISTS consultation_feedback (
    feedback_id BIGINT NOT NULL AUTO_INCREMENT,
    username VARCHAR(128) NOT NULL,
    feedback_type VARCHAR(32) NOT NULL DEFAULT '咨询',
    content VARCHAR(2000) NOT NULL,
    contact VARCHAR(128) NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'Pending',
    idempotency_key VARCHAR(128) NULL,
    created_at DATETIME NOT NULL,
    PRIMARY KEY (feedback_id),
    UNIQUE KEY uk_feedback_idempotency (idempotency_key)
)`

var feedbackStatuses = map[string]struct{}{
	"Pending":    {},
	"Processing": {},
	"Resolved":   {},
	"Completed":  {},
}

type FeedbackError struct {
	Status  int
	Code    string
	Message string
}

func (e *FeedbackError) Error() string {
	if e == nil {
		return ""
	}
	return e.Message
}

type ConsultationFeedbackService struct {
	db *gorm.DB
}

func NewConsultationFeedbackService(db *gorm.DB) *ConsultationFeedbackService {
	return &ConsultationFeedbackService{db: db}
}

func (s *ConsultationFeedbackService) EnsureTable() error {
	if s == nil || s.db == nil {
		return nil
	}
	return s.db.Exec(ensureFeedbackTable).Error
}

func IsStaffRole(authority string) bool {
	role := strings.TrimSpace(authority)
	role = strings.TrimPrefix(role, "ROLE_")
	return role == "ADMIN" || role == "SUPER_ADMIN"
}

func (s *ConsultationFeedbackService) List(username string, staff bool) ([]map[string]any, error) {
	query := `SELECT feedback_id, username, feedback_type, content, contact, status, created_at
		FROM consultation_feedback`
	args := []any{}
	if !staff {
		query += " WHERE username = ?"
		args = append(args, username)
	}
	query += " ORDER BY feedback_id DESC"
	rows, err := s.db.Raw(query, args...).Rows()
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := make([]map[string]any, 0)
	for rows.Next() {
		item, err := scanFeedback(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *ConsultationFeedbackService) Create(username string, staff bool, body map[string]any, idempotencyKey string) (map[string]any, bool, error) {
	key := strings.TrimSpace(idempotencyKey)
	if key != "" && utf8.RuneCountInString(key) > maxFeedbackKey {
		return nil, false, &FeedbackError{Status: 400, Code: "INVALID_ARGUMENT", Message: "幂等键过长"}
	}
	if key != "" {
		existing, found, err := s.findByKey(key)
		if err != nil {
			return nil, false, err
		}
		if found {
			replayed, err := replay(existing, username)
			return replayed, false, err
		}
	}
	content, err := requiredContent(firstText(body, "content", "feedback"))
	if err != nil {
		return nil, false, err
	}
	kind := firstText(body, "feedbackType", "type")
	if kind == "" {
		kind = "咨询"
	}
	contact := firstText(body, "contact")
	status, err := normalizeStatus(firstText(body, "status"), staff, "Pending")
	if err != nil {
		return nil, false, err
	}
	created := time.Now()
	tx := s.db.Begin()
	if tx.Error != nil {
		return nil, false, tx.Error
	}
	err = tx.Exec(`INSERT INTO consultation_feedback
		(username, feedback_type, content, contact, status, idempotency_key, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?)`,
		username, kind, content, blankToNil(contact), status, blankToNil(key), created).Error
	if err != nil {
		tx.Rollback()
		if key != "" && isDuplicateKey(err) {
			existing, found, lookupErr := s.findByKey(key)
			if lookupErr != nil {
				return nil, false, lookupErr
			}
			if found {
				replayed, replayErr := replay(existing, username)
				return replayed, false, replayErr
			}
			// 并发窗口内唯一键被占用但回查不到行：仍按幂等冲突处理，避免 5xx。
			return nil, false, &FeedbackError{Status: 409, Code: "IDEMPOTENCY_CONFLICT", Message: "幂等键已被使用"}
		}
		return nil, false, err
	}
	var id int64
	if err = tx.Raw("SELECT LAST_INSERT_ID()").Scan(&id).Error; err != nil {
		tx.Rollback()
		return nil, false, err
	}
	if err = tx.Commit().Error; err != nil {
		return nil, false, err
	}
	return feedbackJSON(id, username, kind, content, contact, status, created), true, nil
}

func (s *ConsultationFeedbackService) Update(username string, staff bool, feedbackID int64, body map[string]any) (map[string]any, error) {
	current, found, err := s.findByID(feedbackID)
	if err != nil {
		return nil, err
	}
	if !found {
		return nil, &FeedbackError{Status: 404, Code: "NOT_FOUND", Message: "Feedback not found"}
	}
	if !staff && asString(current["username"]) != username {
		return nil, &FeedbackError{Status: 403, Code: "FORBIDDEN", Message: "Forbidden"}
	}
	content := firstText(body, "content", "feedback")
	if content == "" {
		content = asString(current["content"])
	} else {
		content, err = requiredContent(content)
		if err != nil {
			return nil, err
		}
	}
	kind := firstText(body, "feedbackType")
	if kind == "" {
		kind = asString(current["feedbackType"])
	}
	contact := asString(current["contact"])
	if body != nil {
		if _, present := body["contact"]; present {
			contact = firstText(body, "contact")
		}
	}
	status, err := normalizeStatus(firstText(body, "status"), staff, asString(current["status"]))
	if err != nil {
		return nil, err
	}
	if err = s.db.Exec(`UPDATE consultation_feedback
		SET feedback_type = ?, content = ?, contact = ?, status = ?
		WHERE feedback_id = ?`, kind, content, blankToNil(contact), status, feedbackID).Error; err != nil {
		return nil, err
	}
	current["feedbackType"] = kind
	current["content"] = content
	current["feedback"] = content
	current["contact"] = contact
	current["status"] = status
	return current, nil
}

func replay(existing map[string]any, username string) (map[string]any, error) {
	if asString(existing["username"]) != username {
		return nil, &FeedbackError{Status: 409, Code: "IDEMPOTENCY_CONFLICT", Message: "幂等键已被使用"}
	}
	return existing, nil
}

func (s *ConsultationFeedbackService) findByKey(key string) (map[string]any, bool, error) {
	row := s.db.Raw(`SELECT feedback_id, username, feedback_type, content, contact, status, created_at
		FROM consultation_feedback WHERE idempotency_key = ?`, key).Row()
	item, err := scanFeedbackRow(row)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, err
	}
	return item, true, nil
}

func (s *ConsultationFeedbackService) findByID(id int64) (map[string]any, bool, error) {
	row := s.db.Raw(`SELECT feedback_id, username, feedback_type, content, contact, status, created_at
		FROM consultation_feedback WHERE feedback_id = ?`, id).Row()
	item, err := scanFeedbackRow(row)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, err
	}
	return item, true, nil
}

func requiredContent(content string) (string, error) {
	trimmed := strings.TrimSpace(content)
	if trimmed == "" {
		return "", &FeedbackError{Status: 400, Code: "INVALID_ARGUMENT", Message: "反馈内容不能为空"}
	}
	if utf8.RuneCountInString(trimmed) > maxFeedbackContent {
		return "", &FeedbackError{Status: 400, Code: "INVALID_ARGUMENT", Message: "反馈内容过长"}
	}
	return trimmed, nil
}

func normalizeStatus(requested string, staff bool, fallback string) (string, error) {
	if !staff || strings.TrimSpace(requested) == "" {
		if strings.TrimSpace(fallback) == "" {
			return "Pending", nil
		}
		return fallback, nil
	}
	if _, ok := feedbackStatuses[requested]; !ok {
		return "", &FeedbackError{Status: 400, Code: "INVALID_ARGUMENT", Message: "反馈状态不合法"}
	}
	return requested, nil
}

func isDuplicateKey(err error) bool {
	if errors.Is(err, gorm.ErrDuplicatedKey) {
		return true
	}
	var mysqlErr *mysql.MySQLError
	return errors.As(err, &mysqlErr) && mysqlErr.Number == 1062
}

func firstText(body map[string]any, keys ...string) string {
	if body == nil {
		return ""
	}
	for _, key := range keys {
		value, ok := body[key]
		if !ok {
			continue
		}
		text := strings.TrimSpace(asString(value))
		if text != "" {
			return text
		}
	}
	return ""
}

func asString(value any) string {
	switch typed := value.(type) {
	case string:
		return typed
	default:
		return ""
	}
}

func blankToNil(value string) any {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}
	return trimmed
}

type feedbackScanner interface {
	Scan(dest ...any) error
}

func scanFeedback(rows *sql.Rows) (map[string]any, error) {
	return scanFeedbackValues(rows)
}

func scanFeedbackRow(row *sql.Row) (map[string]any, error) {
	return scanFeedbackValues(row)
}

func scanFeedbackValues(scanner feedbackScanner) (map[string]any, error) {
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

func feedbackJSON(id int64, username, kind, content, contact, status string, created time.Time) map[string]any {
	return map[string]any{
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
