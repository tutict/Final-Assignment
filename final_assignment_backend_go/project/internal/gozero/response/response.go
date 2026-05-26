package response

import (
	"net/http"

	"github.com/zeromicro/go-zero/rest/httpx"
)

type APIResponse struct {
	Success   bool   `json:"success"`
	Data      any    `json:"data,omitempty"`
	Message   string `json:"message,omitempty"`
	ErrorCode string `json:"errorCode,omitempty"`
}

type PageResponse[T any] struct {
	Content []T   `json:"content"`
	Total   int64 `json:"total"`
	Page    int   `json:"page"`
	Size    int   `json:"size"`
}

func OK(w http.ResponseWriter, data any) {
	httpx.OkJson(w, APIResponse{
		Success: true,
		Data:    data,
	})
}

func Error(w http.ResponseWriter, status int, code string, message string) {
	ErrorWithData(w, status, code, message, nil)
}

func ErrorWithData(w http.ResponseWriter, status int, code string, message string, data any) {
	httpx.WriteJson(w, status, APIResponse{
		Success:   false,
		Data:      data,
		ErrorCode: code,
		Message:   message,
	})
}

func NotImplemented(w http.ResponseWriter, data any) {
	ErrorWithData(
		w,
		http.StatusNotImplemented,
		"GO_ZERO_ROUTE_NOT_IMPLEMENTED",
		"Route is registered from the Spring Boot contract but its Go service logic has not been migrated yet.",
		data,
	)
}
