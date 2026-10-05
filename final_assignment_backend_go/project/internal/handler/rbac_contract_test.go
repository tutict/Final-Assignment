package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"final_assignment_backend_go/project/internal/domain"

	"github.com/gin-gonic/gin"
)

type roleStub struct{ items []domain.RoleManagement }

func (roleStub) CheckAndInsertIdempotency(string, *domain.RoleManagement, string) error {
	return nil
}
func (roleStub) DeleteRole(string) error                              { return nil }
func (roleStub) DeleteRoleByName(string) error                        { return nil }
func (s roleStub) GetAllRoles() ([]domain.RoleManagement, error)      { return s.items, nil }
func (roleStub) GetRoleById(string) (*domain.RoleManagement, error)   { return nil, nil }
func (roleStub) GetRoleByName(string) (*domain.RoleManagement, error) { return nil, nil }
func (roleStub) GetRolesByNameLike(string) ([]domain.RoleManagement, error) {
	return nil, nil
}

type permissionStub struct{ items []domain.PermissionManagement }

func (permissionStub) CheckAndInsertIdempotency(string, *domain.PermissionManagement, string) error {
	return nil
}
func (permissionStub) DeletePermission(int) error          { return nil }
func (permissionStub) DeletePermissionByName(string) error { return nil }
func (s permissionStub) GetAllPermissions() ([]domain.PermissionManagement, error) {
	return s.items, nil
}
func (permissionStub) GetPermissionById(int) (*domain.PermissionManagement, error) {
	return nil, nil
}
func (permissionStub) GetPermissionByName(string) (*domain.PermissionManagement, error) {
	return nil, nil
}
func (permissionStub) GetPermissionsByNameLike(string) ([]domain.PermissionManagement, error) {
	return nil, nil
}
func (permissionStub) UpdatePermission(int, string, *domain.PermissionManagement) error { return nil }

func TestRoleAndPermissionSearchMatchFrontend(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("normalizedRoles", []string{"ADMIN"})
		c.Next()
	})
	NewRoleManagementController(roleStub{items: []domain.RoleManagement{
		{RoleID: 1, RoleCode: "ADMIN", RoleName: "Administrator", RoleType: "SYSTEM", DataScope: "ALL", Status: "Active"},
		{RoleID: 2, RoleCode: "USER", RoleName: "Driver", RoleType: "BUSINESS", DataScope: "SELF", Status: "Disabled"},
	}}).RegisterRoutes(router)
	parent := 9
	visible := true
	hidden := false
	NewPermissionHandler(permissionStub{items: []domain.PermissionManagement{
		{PermissionID: 3, ParentID: &parent, PermissionCode: "appeal:read", PermissionName: "View appeals", PermissionType: "API", APIPath: "/api/appeals", MenuPath: "/admin/appeals", IsVisible: &visible, Status: "Active"},
		{PermissionID: 4, PermissionCode: "fine:write", PermissionName: "Edit fines", PermissionType: "MENU", APIPath: "/api/fines", MenuPath: "/admin/fines", IsVisible: &hidden, Status: "Disabled"},
	}}).RegisterRoutes(router)

	assertRole := func(path string, wantID int) {
		t.Helper()
		res := httptest.NewRecorder()
		router.ServeHTTP(res, httptest.NewRequest(http.MethodGet, path, nil))
		if res.Code != http.StatusOK {
			t.Fatalf("%s status=%d body=%s", path, res.Code, res.Body.String())
		}
		var body []domain.RoleManagement
		if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
			t.Fatalf("%s %v body=%s", path, err, res.Body.String())
		}
		if len(body) != 1 || body[0].RoleID != wantID {
			t.Fatalf("%s got %#v", path, body)
		}
	}
	assertPermission := func(path string, wantID int) {
		t.Helper()
		res := httptest.NewRecorder()
		router.ServeHTTP(res, httptest.NewRequest(http.MethodGet, path, nil))
		if res.Code != http.StatusOK {
			t.Fatalf("%s status=%d body=%s", path, res.Code, res.Body.String())
		}
		var body []domain.PermissionManagement
		if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
			t.Fatalf("%s %v body=%s", path, err, res.Body.String())
		}
		if len(body) != 1 || body[0].PermissionID != wantID {
			t.Fatalf("%s got %#v", path, body)
		}
	}

	assertRole("/api/roles/search/code/prefix?roleCode=AD", 1)
	assertRole("/api/roles/search/name/fuzzy?roleName=drive", 2)
	assertRole("/api/roles/search/type?roleType=SYSTEM", 1)
	assertRole("/api/roles/search/data-scope?dataScope=SELF", 2)
	assertRole("/api/roles/search/status?status=Disabled", 2)
	code := httptest.NewRecorder()
	router.ServeHTTP(code, httptest.NewRequest(http.MethodGet, "/api/roles/by-code/USER", nil))
	if code.Code != http.StatusOK {
		t.Fatalf("by-code status=%d body=%s", code.Code, code.Body.String())
	}
	assertPermission("/api/permissions/search/code/fuzzy?permissionCode=fine", 4)
	assertPermission("/api/permissions/search/name/prefix?permissionName=View", 3)
	assertPermission("/api/permissions/search/type?permissionType=MENU", 4)
	assertPermission("/api/permissions/search/api-path?apiPath=/api/appeals", 3)
	assertPermission("/api/permissions/search/status?status=Disabled", 4)
	assertPermission("/api/permissions/parent/9", 3)
}
