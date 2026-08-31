package handler

import "github.com/gin-gonic/gin"

// apiResponse 对齐 Spring 的 com.tutict.finalassignmentbackend.dto.response.ApiResponse 信封。
type apiResponse struct {
	Success   bool   `json:"success"`
	Data      any    `json:"data"`
	Message   string `json:"message,omitempty"`
	ErrorCode string `json:"errorCode,omitempty"`
}

func apiOK(data any) apiResponse {
	return apiResponse{Success: true, Data: data}
}

func apiError(code string, message string) apiResponse {
	return apiResponse{Success: false, ErrorCode: code, Message: message}
}

// memberOfRole 判断当前上下文是否持有任一允许角色（role/roles/normalizedRoles）。
func memberOfRole(c *gin.Context, allowed ...string) bool {
	allowedSet := make(map[string]bool, len(allowed))
	for _, role := range allowed {
		allowedSet[role] = true
	}
	if allowedSet[c.GetString("role")] {
		return true
	}
	if roles, ok := c.Get("roles"); ok {
		if values, ok := roles.([]string); ok {
			for _, role := range values {
				if allowedSet[role] {
					return true
				}
			}
		}
	}
	return false
}
