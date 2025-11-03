package statemachine

// ProgressItem 模拟数据库中保存的实体
type ProgressItem struct {
	ID     int64  `json:"id"`
	Status string `json:"status"`
}
