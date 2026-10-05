package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"final_assignment_backend_go/project/internal/domain"

	"github.com/gin-gonic/gin"
)

type rolePermissionStub struct {
	rows []domain.SysRolePermission
}

func (s rolePermissionStub) ListRolePermissions() ([]domain.SysRolePermission, error) {
	return s.rows, nil
}

func TestRolePermissionRoutesMatchFrontend(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	NewRoleManagementController(roleStub{items: []domain.RoleManagement{
		{RoleID: 1, RoleCode: "ADMIN"},
	}}).WithRolePermissions(rolePermissionStub{rows: []domain.SysRolePermission{
		{ID: 11, RoleID: 1, PermissionID: 3},
		{ID: 12, RoleID: 2, PermissionID: 3},
		{ID: 13, RoleID: 1, PermissionID: 9},
	}}).RegisterRoutes(router)

	list := httptest.NewRecorder()
	router.ServeHTTP(list, httptest.NewRequest(http.MethodGet, "/api/roles/1/permissions", nil))
	if list.Code != http.StatusOK {
		t.Fatalf("list status=%d body=%s", list.Code, list.Body.String())
	}
	var rows []domain.SysRolePermission
	if err := json.Unmarshal(list.Body.Bytes(), &rows); err != nil {
		t.Fatal(err)
	}
	if len(rows) != 2 || rows[0].RoleID != 1 || rows[1].RoleID != 1 {
		t.Fatalf("list=%#v", rows)
	}

	search := httptest.NewRecorder()
	router.ServeHTTP(search, httptest.NewRequest(http.MethodGet, "/api/roles/permissions/search?roleId=1&permissionId=9", nil))
	if search.Code != http.StatusOK {
		t.Fatalf("search status=%d body=%s", search.Code, search.Body.String())
	}
	if err := json.Unmarshal(search.Body.Bytes(), &rows); err != nil {
		t.Fatal(err)
	}
	if len(rows) != 1 || rows[0].ID != 13 {
		t.Fatalf("search=%#v", rows)
	}
}
