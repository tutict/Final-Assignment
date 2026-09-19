package handler

import (
	"strings"

	"github.com/gin-gonic/gin"
)

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
		allowedSet[strings.ToUpper(strings.TrimPrefix(strings.TrimSpace(role), "ROLE_"))] = true
	}
	if allowedSet[strings.ToUpper(strings.TrimPrefix(strings.TrimSpace(c.GetString("role")), "ROLE_"))] {
		return true
	}
	for _, key := range []string{"roles", "normalizedRoles"} {
		if roles, ok := c.Get(key); ok {
			if values, ok := roles.([]string); ok {
				for _, role := range values {
					role = strings.ToUpper(strings.TrimPrefix(strings.TrimSpace(role), "ROLE_"))
					if allowedSet[role] {
						return true
					}
				}
			}
		}
	}
	return false
}

func elevatedRequester(c *gin.Context) bool {
	return memberOfRole(c, "ADMIN", "SUPER_ADMIN", "TRAFFIC_POLICE", "FINANCE")
}

func requireStaff(c *gin.Context) bool {
	if memberOfRole(c, "ADMIN", "SUPER_ADMIN", "TRAFFIC_POLICE") {
		return true
	}
	c.JSON(403, gin.H{"error": "access denied"})
	return false
}

func requireFinanceStaff(c *gin.Context) bool {
	if memberOfRole(c, "ADMIN", "SUPER_ADMIN", "TRAFFIC_POLICE", "FINANCE") {
		return true
	}
	c.JSON(403, gin.H{"error": "access denied"})
	return false
}

func RequiresAdminPath(path string) bool {
	if path == "/api/users/me" || path == "/api/users/me/password" {
		return false
	}
	adminPrefixes := []string{
		"/api/auth/users",
		"/api/rag/admin",
		"/api/users",
		"/api/roles",
		"/api/permissions",
		"/api/loginLogs",
		"/api/operationLogs",
		"/api/systemLogs",
		"/api/systemSettings",
		"/api/backups",
		"/api/logs",
		"/api/system/logs",
		"/api/system/settings",
		"/api/system/backup",
	}
	for _, prefix := range adminPrefixes {
		if path == prefix || strings.HasPrefix(path, prefix+"/") {
			return true
		}
	}
	return false
}

func AllowsGovernanceRole(c *gin.Context) bool {
	return memberOfRole(c, "ADMIN", "SUPER_ADMIN")
}
