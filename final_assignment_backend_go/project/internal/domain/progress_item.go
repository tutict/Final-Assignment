package domain

import "time"

// ProgressItem 是 /api/progress 的响应 DTO；持久化复用共享的
// sys_request_history 幂等账本，避免再维护一张与账本脱节的 progress_items 表。
type ProgressItem struct {
	ID         int       `json:"id"`
	Title      string    `json:"title"`
	Status     string    `json:"status"`
	SubmitTime time.Time `json:"submitTime"`
	Details    string    `json:"details"`
	Username   string    `json:"username,omitempty"`
	UserID     *int64    `json:"userId,omitempty"`
}
