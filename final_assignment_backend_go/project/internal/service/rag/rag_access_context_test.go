package rag

import (
	"reflect"
	"testing"
)

func TestNewRagAccessContextDerivesDepartmentFromRoles(t *testing.T) {
	cases := []struct {
		name          string
		userID        string
		roles         []string
		wantRoles     []string
		wantDepartmnt string
	}{
		{
			name:      "no roles stays anonymous",
			userID:    "",
			roles:     nil,
			wantRoles: []string{},
		},
		{
			name:          "system role maps to ALL",
			userID:        "admin-1",
			roles:         []string{"ROLE_ADMIN"},
			wantRoles:     []string{"ADMIN"},
			wantDepartmnt: "ALL",
		},
		{
			name:          "super admin maps to ALL",
			userID:        "root",
			roles:         []string{"super_admin"},
			wantRoles:     []string{"SUPER_ADMIN"},
			wantDepartmnt: "ALL",
		},
		{
			name:          "business role maps to DEPARTMENT",
			userID:        "finance-1",
			roles:         []string{"FINANCE"},
			wantRoles:     []string{"FINANCE"},
			wantDepartmnt: "DEPARTMENT",
		},
		{
			name:      "plain user has no department",
			userID:    "driver-1",
			roles:     []string{"USER"},
			wantRoles: []string{"USER"},
		},
	}

	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			got := NewRagAccessContext(testCase.userID, testCase.roles)
			if got.UserID != testCase.userID {
				t.Fatalf("UserID = %q, want %q", got.UserID, testCase.userID)
			}
			if len(got.Roles) != len(testCase.wantRoles) || (len(got.Roles) > 0 && !reflect.DeepEqual(got.Roles, testCase.wantRoles)) {
				t.Fatalf("Roles = %#v, want %#v", got.Roles, testCase.wantRoles)
			}
			if got.Department != testCase.wantDepartmnt {
				t.Fatalf("Department = %q, want %q", got.Department, testCase.wantDepartmnt)
			}
		})
	}
}

func TestNewRagAccessContextDropsDuplicateRoles(t *testing.T) {
	got := NewRagAccessContext("u1", []string{"USER", "user", "ROLE_USER"})
	if len(got.Roles) != 1 || got.Roles[0] != "USER" {
		t.Fatalf("Roles = %#v, want [USER]", got.Roles)
	}
}
