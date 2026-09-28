package reliability

import (
	"context"
	"errors"
	"strings"
)

func ConnectionWait(err error) bool {
	if err == nil {
		return false
	}
	if errors.Is(err, context.DeadlineExceeded) {
		return true
	}
	message := strings.ToLower(err.Error())
	return strings.Contains(message, "i/o timeout") ||
		strings.Contains(message, "context deadline exceeded") ||
		strings.Contains(message, "acquisition timeout") ||
		strings.Contains(message, "bad connection") ||
		strings.Contains(message, "invalid connection") ||
		strings.Contains(message, "too many connections") ||
		strings.Contains(message, "connection refused") ||
		strings.Contains(message, "connection reset") ||
		strings.Contains(message, "broken pipe") ||
		strings.Contains(message, "lock wait timeout") ||
		strings.Contains(message, "deadlock")
}
