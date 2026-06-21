package ai

import (
	"testing"
)

func TestRoleResolver_ResolveFromMetadata(t *testing.T) {
	resolver := NewRoleResolver()

	tests := []struct {
		name     string
		metadata map[string]any
		want     []string
	}{
		{
			name:     "nil metadata",
			metadata: nil,
			want:     []string{"DRIVER"},
		},
		{
			name:     "empty metadata",
			metadata: map[string]any{},
			want:     []string{"DRIVER"},
		},
		{
			name: "roles as string slice",
			metadata: map[string]any{
				"roles": []string{"admin", "driver"},
			},
			want: []string{"ADMIN", "DRIVER"},
		},
		{
			name: "roles as interface slice",
			metadata: map[string]any{
				"roles": []any{"admin", "moderator"},
			},
			want: []string{"ADMIN", "MODERATOR"},
		},
		{
			name: "single role as string",
			metadata: map[string]any{
				"roles": "super_admin",
			},
			want: []string{"SUPER_ADMIN"},
		},
		{
			name: "role field (singular)",
			metadata: map[string]any{
				"role": "admin",
			},
			want: []string{"ADMIN"},
		},
		{
			name: "roles in JWT claims",
			metadata: map[string]any{
				"claims": map[string]any{
					"roles": []string{"admin", "manager"},
				},
			},
			want: []string{"ADMIN", "MANAGER"},
		},
		{
			name: "roles in user object",
			metadata: map[string]any{
				"user": map[string]any{
					"roles": []string{"driver"},
				},
			},
			want: []string{"DRIVER"},
		},
		{
			name: "duplicate roles",
			metadata: map[string]any{
				"roles": []string{"admin", "ADMIN", "Admin"},
			},
			want: []string{"ADMIN"},
		},
		{
			name: "mixed case normalization",
			metadata: map[string]any{
				"roles": []string{"DrIvEr", "aDmIn"},
			},
			want: []string{"DRIVER", "ADMIN"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := resolver.ResolveFromMetadata(tt.metadata)
			if len(got) != len(tt.want) {
				t.Errorf("ResolveFromMetadata() got %v, want %v", got, tt.want)
				return
			}
			for i := range got {
				if got[i] != tt.want[i] {
					t.Errorf("ResolveFromMetadata() got %v, want %v", got, tt.want)
					return
				}
			}
		})
	}
}

func TestRoleResolver_GetHighestPriorityRole(t *testing.T) {
	resolver := NewRoleResolver()

	tests := []struct {
		name  string
		roles []string
		want  string
	}{
		{
			name:  "empty roles",
			roles: []string{},
			want:  "DRIVER",
		},
		{
			name:  "single role",
			roles: []string{"admin"},
			want:  "ADMIN",
		},
		{
			name:  "super_admin is highest",
			roles: []string{"driver", "admin", "super_admin"},
			want:  "SUPER_ADMIN",
		},
		{
			name:  "admin higher than driver",
			roles: []string{"driver", "admin"},
			want:  "ADMIN",
		},
		{
			name:  "case insensitive",
			roles: []string{"DrIvEr", "AdMiN"},
			want:  "ADMIN",
		},
		{
			name:  "unknown roles default to driver",
			roles: []string{"unknown_role"},
			want:  "DRIVER",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := resolver.GetHighestPriorityRole(tt.roles)
			if got != tt.want {
				t.Errorf("GetHighestPriorityRole() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestRoleResolver_HasRole(t *testing.T) {
	resolver := NewRoleResolver()

	tests := []struct {
		name       string
		roles      []string
		targetRole string
		want       bool
	}{
		{
			name:       "role exists",
			roles:      []string{"ADMIN", "DRIVER"},
			targetRole: "admin",
			want:       true,
		},
		{
			name:       "role does not exist",
			roles:      []string{"DRIVER"},
			targetRole: "admin",
			want:       false,
		},
		{
			name:       "case insensitive match",
			roles:      []string{"ADMIN"},
			targetRole: "AdMiN",
			want:       true,
		},
		{
			name:       "empty roles",
			roles:      []string{},
			targetRole: "admin",
			want:       false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := resolver.HasRole(tt.roles, tt.targetRole)
			if got != tt.want {
				t.Errorf("HasRole() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestRoleResolver_HasAnyRole(t *testing.T) {
	resolver := NewRoleResolver()

	tests := []struct {
		name        string
		roles       []string
		targetRoles []string
		want        bool
	}{
		{
			name:        "has one of target roles",
			roles:       []string{"DRIVER", "MODERATOR"},
			targetRoles: []string{"ADMIN", "MODERATOR"},
			want:        true,
		},
		{
			name:        "has none of target roles",
			roles:       []string{"DRIVER"},
			targetRoles: []string{"ADMIN", "SUPER_ADMIN"},
			want:        false,
		},
		{
			name:        "empty target roles",
			roles:       []string{"ADMIN"},
			targetRoles: []string{},
			want:        false,
		},
		{
			name:        "empty roles",
			roles:       []string{},
			targetRoles: []string{"ADMIN"},
			want:        false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := resolver.HasAnyRole(tt.roles, tt.targetRoles)
			if got != tt.want {
				t.Errorf("HasAnyRole() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestRoleResolver_ValidateRole(t *testing.T) {
	resolver := NewRoleResolver()

	tests := []struct {
		name    string
		role    string
		wantErr bool
	}{
		{
			name:    "valid role - admin",
			role:    "admin",
			wantErr: false,
		},
		{
			name:    "valid role - super_admin",
			role:    "super_admin",
			wantErr: false,
		},
		{
			name:    "valid role - driver",
			role:    "DRIVER",
			wantErr: false,
		},
		{
			name:    "invalid role",
			role:    "unknown_role",
			wantErr: true,
		},
		{
			name:    "empty role",
			role:    "",
			wantErr: true,
		},
		{
			name:    "whitespace role",
			role:    "   ",
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := resolver.ValidateRole(tt.role)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateRole() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestRoleResolver_SetDefaultRole(t *testing.T) {
	resolver := NewRoleResolver()

	// Default should be DRIVER
	if resolver.defaultRole != "DRIVER" {
		t.Errorf("Initial defaultRole = %s, want DRIVER", resolver.defaultRole)
	}

	// Change default
	resolver.SetDefaultRole("user")
	if resolver.defaultRole != "USER" {
		t.Errorf("After SetDefaultRole, defaultRole = %s, want USER", resolver.defaultRole)
	}

	// Verify it's used when no roles provided
	roles := resolver.ResolveFromMetadata(map[string]any{})
	if len(roles) != 1 || roles[0] != "USER" {
		t.Errorf("ResolveFromMetadata() with no roles = %v, want [USER]", roles)
	}
}

func TestRoleResolver_ParseRolesValue(t *testing.T) {
	resolver := NewRoleResolver()

	tests := []struct {
		name  string
		value any
		want  []string
	}{
		{
			name:  "string value",
			value: "admin",
			want:  []string{"admin"},
		},
		{
			name:  "empty string",
			value: "",
			want:  []string{},
		},
		{
			name:  "string slice",
			value: []string{"admin", "driver"},
			want:  []string{"admin", "driver"},
		},
		{
			name:  "interface slice",
			value: []any{"admin", "driver"},
			want:  []string{"admin", "driver"},
		},
		{
			name:  "interface slice with non-strings",
			value: []any{"admin", 123, "driver"},
			want:  []string{"admin", "driver"},
		},
		{
			name:  "unexpected type",
			value: 123,
			want:  []string{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := resolver.parseRolesValue(tt.value)
			if len(got) != len(tt.want) {
				t.Errorf("parseRolesValue() got %v, want %v", got, tt.want)
				return
			}
			for i := range got {
				if got[i] != tt.want[i] {
					t.Errorf("parseRolesValue() got %v, want %v", got, tt.want)
					return
				}
			}
		})
	}
}
