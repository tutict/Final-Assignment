package handler

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestRequiresAdminPath(t *testing.T) {
	gin.SetMode(gin.TestMode)
	cases := map[string]bool{
		"/api/users":              true,
		"/api/users/1":            true,
		"/api/users/me":           false,
		"/api/users/me/password":  false,
		"/api/rag/admin":          true,
		"/api/rag/admin/docs":     true,
		"/api/permissions":        true,
		"/api/logs/login":         true,
		"/api/system/settings":    true,
		"/api/fines":              false,
		"/api/drivers":            false,
		"/api/auth/login":         false,
	}
	for path, want := range cases {
		if got := RequiresAdminPath(path); got != want {
			t.Fatalf("RequiresAdminPath(%q)=%v want %v", path, got, want)
		}
	}
}

func contextWithRole(role string) *gin.Context {
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("role", role)
	c.Set("normalizedRoles", []string{role})
	c.Request = httptest.NewRequest(http.MethodGet, "/", nil)
	return c
}

func TestAllowsGovernanceRole(t *testing.T) {
	gin.SetMode(gin.TestMode)
	if !AllowsGovernanceRole(contextWithRole("SUPER_ADMIN")) {
		t.Fatal("SUPER_ADMIN should pass governance")
	}
	if !AllowsGovernanceRole(contextWithRole("ADMIN")) {
		t.Fatal("ADMIN should pass governance")
	}
	if AllowsGovernanceRole(contextWithRole("USER")) {
		t.Fatal("USER should not pass governance")
	}
	if AllowsGovernanceRole(contextWithRole("TRAFFIC_POLICE")) {
		t.Fatal("TRAFFIC_POLICE should not pass governance admin paths")
	}
}

func TestElevatedRequester(t *testing.T) {
	gin.SetMode(gin.TestMode)
	if !elevatedRequester(contextWithRole("FINANCE")) {
		t.Fatal("FINANCE should be elevated for business reads")
	}
	if elevatedRequester(contextWithRole("USER")) {
		t.Fatal("USER should not be elevated")
	}
}

func TestRequireStaff(t *testing.T) {
	gin.SetMode(gin.TestMode)
	staff := contextWithRole("TRAFFIC_POLICE")
	if !requireStaff(staff) {
		t.Fatal("TRAFFIC_POLICE should write drivers/vehicles")
	}
	user := contextWithRole("USER")
	if requireStaff(user) {
		t.Fatal("USER should not be staff")
	}
	finance := contextWithRole("FINANCE")
	if requireStaff(finance) {
		t.Fatal("FINANCE should not write driver/vehicle records")
	}
	if !requireFinanceStaff(finance) {
		t.Fatal("FINANCE should write fines/deductions")
	}
}
