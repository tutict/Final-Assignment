package service

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
	"sync"
	"time"

	"gorm.io/gorm"
)

var ErrNotFound = gorm.ErrRecordNotFound

var idempotencyLedger = struct {
	sync.Mutex
	seen map[string]string
}{
	seen: map[string]string{},
}

func checkIdempotency(key string, operation string) error {
	key = strings.TrimSpace(key)
	if key == "" {
		return nil
	}
	idempotencyLedger.Lock()
	defer idempotencyLedger.Unlock()

	scope := operation + ":" + key
	if _, exists := idempotencyLedger.seen[scope]; exists {
		return errors.New("Duplicate request")
	}
	idempotencyLedger.seen[scope] = time.Now().UTC().Format(time.RFC3339Nano)
	return nil
}

func parseID(value string) (int, error) {
	id, err := strconv.Atoi(strings.TrimSpace(value))
	if err != nil || id <= 0 {
		return 0, fmt.Errorf("invalid id: %s", value)
	}
	return id, nil
}

func pageBounds(page int, size int) (int, int) {
	if page < 1 {
		page = 1
	}
	if size < 1 {
		size = 10
	}
	if size > 100 {
		size = 100
	}
	return (page - 1) * size, size
}

func like(value string) string {
	return "%" + strings.TrimSpace(value) + "%"
}

func prefixLike(value string) string {
	return strings.TrimSpace(value) + "%"
}

func timePtr(t time.Time) *time.Time {
	return &t
}

func isMissingTable(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "1146") || strings.Contains(msg, "doesn't exist") || strings.Contains(msg, "does not exist")
}

func requesterDriverID(db *gorm.DB, username string) (int, bool) {
	username = strings.TrimSpace(username)
	if username == "" {
		return 0, false
	}
	var id int
	err := db.Table("driver_information").
		Select("driver_information.driver_id").
		Joins("JOIN sys_user ON sys_user.user_id = driver_information.auth_user_id AND sys_user.deleted_at IS NULL").
		Where("sys_user.username = ? AND driver_information.deleted_at IS NULL", username).
		Limit(1).
		Scan(&id).Error
	return id, err == nil && id > 0
}

func distinctStrings(db *gorm.DB, table string, column string, prefix string, limit int) []string {
	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}
	var values []string
	query := db.Table(table).Select("DISTINCT " + column).Where(column + " IS NOT NULL AND " + column + " <> ''")
	if strings.TrimSpace(prefix) != "" {
		query = query.Where(column+" LIKE ?", prefixLike(prefix))
	}
	_ = query.Order(column).Limit(limit).Pluck(column, &values).Error
	return values
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return value
		}
	}
	return ""
}

func atoiDefault(value string, fallback int) int {
	if parsed, err := strconv.Atoi(strings.TrimSpace(value)); err == nil {
		return parsed
	}
	return fallback
}
