package handler

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestRequiresAdminPath(t *testing.T) {
	cases := map[string]bool{
		"/api/users":             true,
		"/api/users/1":           true,
		"/api/users/me":          false,
		"/api/users/me/password": false,
		"/api/rag/admin":         true,
		"/api/rag/admin/docs":    true,
		"/api/permissions":       true,
		"/api/logs/login":        true,
		"/api/system/settings":   true,
		"/api/fines":             false,
		"/api/drivers":           false,
		"/api/auth/login":        false,
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

func TestCapabilityTable(t *testing.T) {
	gin.SetMode(gin.TestMode)
	cases := []struct {
		role string
		cap  Capability
		want bool
	}{
		{"SUPER_ADMIN", CapGovernance, true},
		{"ADMIN", CapGovernance, true},
		{"USER", CapGovernance, false},
		{"TRAFFIC_POLICE", CapGovernance, false},
		{"FINANCE", CapGovernance, false},
		{"TRAFFIC_POLICE", CapStaffWrite, true},
		{"FINANCE", CapStaffWrite, false},
		{"USER", CapStaffWrite, false},
		{"FINANCE", CapFinanceWrite, true},
		{"TRAFFIC_POLICE", CapFinanceWrite, true},
		{"USER", CapFinanceWrite, false},
		{"FINANCE", CapElevatedRead, true},
		{"USER", CapElevatedRead, false},
		{"FINANCE", CapFinanceRead, true},
		{"TRAFFIC_POLICE", CapFinanceRead, false},
		{"USER", CapFinanceRead, false},
	}
	for _, tc := range cases {
		got := HasCapability(contextWithRole(tc.role), tc.cap)
		if got != tc.want {
			t.Fatalf("HasCapability(%s,%s)=%v want %v", tc.role, tc.cap, got, tc.want)
		}
	}
}

func TestResourcePolicyTable(t *testing.T) {
	gin.SetMode(gin.TestMode)
	if !Unscoped(contextWithRole("FINANCE"), ResourceFines) {
		t.Fatal("FINANCE should unscoped-read fines")
	}
	if Unscoped(contextWithRole("USER"), ResourceDrivers) {
		t.Fatal("USER should not unscoped-read drivers")
	}
	if Unscoped(contextWithRole("TRAFFIC_POLICE"), ResourcePayments) {
		t.Fatal("TRAFFIC_POLICE should not unscoped-read payments")
	}
	if !Unscoped(contextWithRole("FINANCE"), ResourcePayments) {
		t.Fatal("FINANCE should unscoped-read payments")
	}

	staff := contextWithRole("TRAFFIC_POLICE")
	if !RequireWrite(staff, ResourceDrivers) {
		t.Fatal("TRAFFIC_POLICE should write drivers")
	}
	user := contextWithRole("USER")
	if RequireWrite(user, ResourceDrivers) {
		t.Fatal("USER should not write drivers")
	}
	finance := contextWithRole("FINANCE")
	if RequireWrite(finance, ResourceDrivers) {
		t.Fatal("FINANCE should not write drivers")
	}
	if !RequireWrite(finance, ResourceFines) {
		t.Fatal("FINANCE should write fines")
	}
}
