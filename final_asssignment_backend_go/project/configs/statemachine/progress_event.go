package statemachine

// ProgressEvent 定义状态机可触发的事件
type ProgressEvent string

const (
	EventSubmit          ProgressEvent = "SUBMIT"
	EventStartProcessing ProgressEvent = "START_PROCESSING"
	EventComplete        ProgressEvent = "COMPLETE"
	EventArchive         ProgressEvent = "ARCHIVE"
	EventReopen          ProgressEvent = "REOPEN"
)
