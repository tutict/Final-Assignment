package ai

import (
	"os"
	"path/filepath"
	"testing"
)

func TestAgentConstraintsLoader_LoadForRole(t *testing.T) {
	// Create temp directory for test files
	tempDir, err := os.MkdirTemp("", "agent_constraints_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test constraint files
	testConstraints := map[string]string{
		"driver.md": `# Driver Constraints
- Can only view own violations
- Cannot access admin functions`,
		"admin.md": `# Admin Constraints
- Can view all violations in department
- Can manage users`,
		"super_admin_policy.md": `# Super Admin Policy
- Full system access
- Can modify all records`,
	}

	for filename, content := range testConstraints {
		filePath := filepath.Join(tempDir, filename)
		if err := os.WriteFile(filePath, []byte(content), 0644); err != nil {
			t.Fatalf("Failed to write test file %s: %v", filename, err)
		}
	}

	loader := NewAgentConstraintsLoader(tempDir)

	tests := []struct {
		name        string
		role        string
		wantErr     bool
		wantContain string
	}{
		{
			name:        "load driver constraints",
			role:        "driver",
			wantErr:     false,
			wantContain: "Driver Constraints",
		},
		{
			name:        "load admin constraints",
			role:        "ADMIN",
			wantErr:     false,
			wantContain: "Admin Constraints",
		},
		{
			name:        "load super_admin with policy suffix",
			role:        "super_admin",
			wantErr:     false,
			wantContain: "Super Admin Policy",
		},
		{
			name:    "role not found",
			role:    "unknown_role",
			wantErr: true,
		},
		{
			name:    "empty role",
			role:    "",
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			content, err := loader.LoadForRole(tt.role)

			if tt.wantErr {
				if err == nil {
					t.Errorf("LoadForRole() expected error, got nil")
				}
				return
			}

			if err != nil {
				t.Errorf("LoadForRole() error = %v", err)
				return
			}

			if tt.wantContain != "" && !containsSubstring(content, tt.wantContain) {
				t.Errorf("LoadForRole() content does not contain %q", tt.wantContain)
			}
		})
	}
}

func TestAgentConstraintsLoader_Cache(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "agent_constraints_cache_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test file
	testFile := filepath.Join(tempDir, "driver.md")
	originalContent := "Original content"
	if err := os.WriteFile(testFile, []byte(originalContent), 0644); err != nil {
		t.Fatalf("Failed to write test file: %v", err)
	}

	loader := NewAgentConstraintsLoader(tempDir)

	// First load
	content1, err := loader.LoadForRole("driver")
	if err != nil {
		t.Fatalf("First load error: %v", err)
	}
	if content1 != originalContent {
		t.Errorf("First load got %q, want %q", content1, originalContent)
	}

	// Modify file
	newContent := "Modified content"
	if err := os.WriteFile(testFile, []byte(newContent), 0644); err != nil {
		t.Fatalf("Failed to modify test file: %v", err)
	}

	// Second load (should return cached content)
	content2, err := loader.LoadForRole("driver")
	if err != nil {
		t.Fatalf("Second load error: %v", err)
	}
	if content2 != originalContent {
		t.Errorf("Second load should return cached content %q, got %q", originalContent, content2)
	}

	// Reload (should bypass cache)
	content3, err := loader.Reload("driver")
	if err != nil {
		t.Fatalf("Reload error: %v", err)
	}
	if content3 != newContent {
		t.Errorf("Reload should return new content %q, got %q", newContent, content3)
	}
}

func TestAgentConstraintsLoader_LoadAll(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "agent_constraints_loadall_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create multiple test files
	testFiles := map[string]string{
		"driver.md":      "Driver policy",
		"admin.md":       "Admin policy",
		"moderator.md":   "Moderator policy",
		"readme.txt":     "Not a policy file",
		"subdir/test.md": "Should be ignored",
	}

	for filename, content := range testFiles {
		filePath := filepath.Join(tempDir, filename)
		dir := filepath.Dir(filePath)
		if dir != tempDir {
			os.MkdirAll(dir, 0755)
		}
		if err := os.WriteFile(filePath, []byte(content), 0644); err != nil {
			t.Fatalf("Failed to write %s: %v", filename, err)
		}
	}

	loader := NewAgentConstraintsLoader(tempDir)
	all, err := loader.LoadAll()
	if err != nil {
		t.Fatalf("LoadAll() error = %v", err)
	}

	// Should load only .md files in root directory
	expectedRoles := []string{"driver", "admin", "moderator"}
	if len(all) != len(expectedRoles) {
		t.Errorf("LoadAll() loaded %d files, want %d", len(all), len(expectedRoles))
	}

	for _, role := range expectedRoles {
		if _, exists := all[role]; !exists {
			t.Errorf("LoadAll() missing role %s", role)
		}
	}

	// Should not load non-.md files
	if _, exists := all["readme"]; exists {
		t.Error("LoadAll() should not load non-.md files")
	}
}

func TestAgentConstraintsLoader_ClearCache(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "agent_constraints_clear_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	testFile := filepath.Join(tempDir, "driver.md")
	if err := os.WriteFile(testFile, []byte("test content"), 0644); err != nil {
		t.Fatalf("Failed to write test file: %v", err)
	}

	loader := NewAgentConstraintsLoader(tempDir)

	// Load to populate cache
	_, err = loader.LoadForRole("driver")
	if err != nil {
		t.Fatalf("LoadForRole error: %v", err)
	}

	// Verify cache has entry
	loader.mutex.RLock()
	cacheSize := len(loader.cache)
	loader.mutex.RUnlock()
	if cacheSize != 1 {
		t.Errorf("Cache should have 1 entry, got %d", cacheSize)
	}

	// Clear cache
	loader.ClearCache()

	// Verify cache is empty
	loader.mutex.RLock()
	cacheSize = len(loader.cache)
	loader.mutex.RUnlock()
	if cacheSize != 0 {
		t.Errorf("Cache should be empty after clear, got %d entries", cacheSize)
	}
}

func TestAgentConstraintsLoader_NonExistentDirectory(t *testing.T) {
	loader := NewAgentConstraintsLoader("/nonexistent/path/to/constraints")

	_, err := loader.LoadAll()
	if err == nil {
		t.Error("LoadAll() should return error for non-existent directory")
	}
}
