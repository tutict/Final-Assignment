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
