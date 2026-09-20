package handler

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// Capability 是角色集合的名字。路径闸门和资源闸门都只查这一份表。
type Capability string

const (
	CapGovernance   Capability = "governance"
	CapStaffWrite   Capability = "staff_write"
	CapFinanceWrite Capability = "finance_write"
	CapElevatedRead Capability = "elevated_read"
	CapFinanceRead  Capability = "finance_read"
	CapSuperAdmin   Capability = "super_admin"
)

var capabilityRoles = map[Capability][]string{
	CapGovernance:   {"ADMIN", "SUPER_ADMIN"},
	CapStaffWrite:   {"ADMIN", "SUPER_ADMIN", "TRAFFIC_POLICE"},
	CapFinanceWrite: {"ADMIN", "SUPER_ADMIN", "TRAFFIC_POLICE", "FINANCE"},
	CapElevatedRead: {"ADMIN", "SUPER_ADMIN", "TRAFFIC_POLICE", "FINANCE"},
	CapFinanceRead:  {"ADMIN", "SUPER_ADMIN", "FINANCE"},
	CapSuperAdmin:   {"SUPER_ADMIN"},
}

// Resource 是业务资源名。写操作和未过滤读取都从 resourcePolicies 取值。
type Resource string

const (
	ResourceDrivers    Resource = "drivers"
	ResourceVehicles   Resource = "vehicles"
	ResourceOffenses   Resource = "offenses"
	ResourceAppeals    Resource = "appeals"
	ResourceFines      Resource = "fines"
	ResourceDeductions Resource = "deductions"
	ResourceProgress   Resource = "progress"
	ResourcePayments   Resource = "payments"
)

type resourcePolicy struct {
	Write        Capability
	UnscopedRead Capability
}

var resourcePolicies = map[Resource]resourcePolicy{
	ResourceDrivers:    {Write: CapStaffWrite, UnscopedRead: CapElevatedRead},
	ResourceVehicles:   {Write: CapStaffWrite, UnscopedRead: CapElevatedRead},
	ResourceOffenses:   {Write: CapStaffWrite, UnscopedRead: CapElevatedRead},
	ResourceAppeals:    {Write: CapStaffWrite, UnscopedRead: CapElevatedRead},
	ResourceFines:      {Write: CapFinanceWrite, UnscopedRead: CapElevatedRead},
	ResourceDeductions: {Write: CapFinanceWrite, UnscopedRead: CapElevatedRead},
	ResourceProgress:   {UnscopedRead: CapElevatedRead},
	ResourcePayments:   {UnscopedRead: CapFinanceRead},
}

type pathPolicy struct {
	prefixes []string
	excludes []string
	require  Capability
}

var pathPolicies = []pathPolicy{{
	prefixes: []string{
		"/api/rag/admin",
	},
	require: CapGovernance,
}, {
	prefixes: []string{
		"/api/loginLogs",
		"/api/operationLogs",
		"/api/systemLogs",
		"/api/logs",
		"/api/system/logs",
	},
	require: CapSuperAdmin,
}, {
	prefixes: []string{
		"/api/auth/users",
		"/api/users",
		"/api/roles",
		"/api/permissions",
		"/api/systemSettings",
		"/api/backups",
		"/api/system/settings",
		"/api/system/backup",
	},
	excludes: []string{"/api/users/me", "/api/users/me/password"},
	require:  CapGovernance,
}}

func HasCapability(c *gin.Context, cap Capability) bool {
	roles, ok := capabilityRoles[cap]
	if !ok {
		return false
	}
	return memberOfRole(c, roles...)
}

func Unscoped(c *gin.Context, resource Resource) bool {
	policy, ok := resourcePolicies[resource]
	if !ok || policy.UnscopedRead == "" {
		return false
	}
	return HasCapability(c, policy.UnscopedRead)
}

func RequireWrite(c *gin.Context, resource Resource) bool {
	policy, ok := resourcePolicies[resource]
	if !ok || policy.Write == "" || !HasCapability(c, policy.Write) {
		c.JSON(http.StatusForbidden, gin.H{"error": "access denied"})
		return false
	}
	return true
}

func RequireUnscoped(c *gin.Context, resource Resource) bool {
	if Unscoped(c, resource) {
		return true
	}
	c.JSON(http.StatusForbidden, gin.H{"error": "access denied"})
	return false
}

func requiredCapabilityForPath(path string) (Capability, bool) {
	for _, rule := range pathPolicies {
		if pathExcluded(path, rule.excludes) {
			continue
		}
		if pathMatches(path, rule.prefixes) {
			return rule.require, true
		}
	}
	return "", false
}

func AllowsPath(c *gin.Context, path string) bool {
	cap, ok := requiredCapabilityForPath(path)
	if !ok {
		return true
	}
	return HasCapability(c, cap)
}

// AccessPolicy 用 pathPolicies 拦截治理路径，取代散落的 RequiresAdminPath if。
func AccessPolicy() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !AllowsPath(c, c.Request.URL.Path) {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "access denied"})
			return
		}
		c.Next()
	}
}

// RequiresAdminPath 由 pathPolicies 派生，保持路径判定的单一来源。
func RequiresAdminPath(path string) bool {
	_, ok := requiredCapabilityForPath(path)
	return ok
}

func AllowsGovernanceRole(c *gin.Context) bool {
	return HasCapability(c, CapGovernance)
}

func pathExcluded(path string, excludes []string) bool {
	for _, exclude := range excludes {
		if path == exclude {
			return true
		}
	}
	return false
}

func pathMatches(path string, prefixes []string) bool {
	for _, prefix := range prefixes {
		if path == prefix || strings.HasPrefix(path, prefix+"/") {
			return true
		}
	}
	return false
}
