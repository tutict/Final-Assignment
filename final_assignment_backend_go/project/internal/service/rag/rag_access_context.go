package rag

import "strings"

// KnownRagRoles 是检索链路可能出现的角色码全集，与 JWT 中登记的角色取值一致。
var KnownRagRoles = []string{
	"SUPER_ADMIN",
	"ADMIN",
	"TRAFFIC_POLICE",
	"FINANCE",
	"APPEAL_REVIEWER",
	"USER",
}

var ragSystemRoles = map[string]struct{}{
	"SUPER_ADMIN": {},
	"ADMIN":       {},
}

var ragDepartmentRoles = map[string]struct{}{
	"TRAFFIC_POLICE":  {},
	"FINANCE":         {},
	"APPEAL_REVIEWER": {},
}

// NewRagAccessContext 构造检索身份。
//
// 角色集合只能来自服务端鉴权结果，部门归属由角色推导，调用方无法自行声明身份。
func NewRagAccessContext(userID string, roles []string) RagAccessContext {
	normalized := normalizeRagRoles(roles)
	return RagAccessContext{
		UserID:     strings.TrimSpace(userID),
		Roles:      normalized,
		Department: ragDepartmentOf(normalized),
	}
}

func normalizeRagRoles(roles []string) []string {
	normalized := make([]string, 0, len(roles))
	seen := make(map[string]struct{}, len(roles))
	for _, role := range roles {
		value := strings.ToUpper(strings.TrimSpace(role))
		value = strings.TrimPrefix(value, "ROLE_")
		if value == "" {
			continue
		}
		if _, ok := seen[value]; ok {
			continue
		}
		seen[value] = struct{}{}
		normalized = append(normalized, value)
	}
	return normalized
}

// ragDepartmentOf 按 Spring 参考实现推导部门归属：系统角色对应 ALL，业务角色对应 DEPARTMENT。
func ragDepartmentOf(roles []string) string {
	for _, role := range roles {
		if _, ok := ragSystemRoles[role]; ok {
			return "ALL"
		}
	}
	for _, role := range roles {
		if _, ok := ragDepartmentRoles[role]; ok {
			return "DEPARTMENT"
		}
	}
	return ""
}
