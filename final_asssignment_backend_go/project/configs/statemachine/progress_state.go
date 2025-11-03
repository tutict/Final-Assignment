package statemachine

// ProgressState 定义状态枚举
type ProgressState string

const (
	StatePending    ProgressState = "PENDING"
	StateProcessing ProgressState = "PROCESSING"
	StateCompleted  ProgressState = "COMPLETED"
	StateArchived   ProgressState = "ARCHIVED"
)
