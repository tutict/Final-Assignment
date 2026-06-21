package ai

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

// AgentConstraintsLoader loads agent constraint policies from markdown files
type AgentConstraintsLoader struct {
	basePath string
	cache    map[string]string
	mutex    sync.RWMutex
}

// NewAgentConstraintsLoader creates a new loader with the specified base directory
func NewAgentConstraintsLoader(basePath string) *AgentConstraintsLoader {
	return &AgentConstraintsLoader{
		basePath: basePath,
		cache:    make(map[string]string),
	}
}

// LoadForRole loads agent constraints for a specific role
// Looks for files like: {basePath}/driver.md, {basePath}/admin.md
func (acl *AgentConstraintsLoader) LoadForRole(role string) (string, error) {
	if role == "" {
		return "", fmt.Errorf("role cannot be empty")
	}

	// Normalize role name to lowercase
	normalizedRole := strings.ToLower(strings.TrimSpace(role))

	// Check cache first
	acl.mutex.RLock()
	if cached, exists := acl.cache[normalizedRole]; exists {
		acl.mutex.RUnlock()
		return cached, nil
	}
	acl.mutex.RUnlock()

	// Load from file
	content, err := acl.loadFromFile(normalizedRole)
	if err != nil {
		return "", err
	}

	// Cache the result
	acl.mutex.Lock()
	acl.cache[normalizedRole] = content
	acl.mutex.Unlock()

	return content, nil
}

// loadFromFile reads the constraint file for a role
func (acl *AgentConstraintsLoader) loadFromFile(normalizedRole string) (string, error) {
	// Try different file naming conventions
	possibleNames := []string{
		normalizedRole + ".md",
		normalizedRole + "_constraints.md",
		normalizedRole + "_policy.md",
	}

	for _, filename := range possibleNames {
		filePath := filepath.Join(acl.basePath, filename)
		content, err := os.ReadFile(filePath)
		if err == nil {
			return string(content), nil
		}
		// Continue to next possible name if file not found
		if !os.IsNotExist(err) {
			return "", fmt.Errorf("error reading %s: %w", filePath, err)
		}
	}

	return "", fmt.Errorf("no constraint file found for role %s in %s", normalizedRole, acl.basePath)
}

// LoadAll loads all constraint files from the base directory
func (acl *AgentConstraintsLoader) LoadAll() (map[string]string, error) {
	result := make(map[string]string)

	// Check if directory exists
	if _, err := os.Stat(acl.basePath); os.IsNotExist(err) {
		return result, fmt.Errorf("constraints directory does not exist: %s", acl.basePath)
	}

	// Read all .md files
	entries, err := os.ReadDir(acl.basePath)
	if err != nil {
		return result, fmt.Errorf("failed to read directory %s: %w", acl.basePath, err)
	}

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		name := entry.Name()
		if !strings.HasSuffix(name, ".md") {
			continue
		}

		// Extract role name from filename
		role := strings.TrimSuffix(name, ".md")
		role = strings.TrimSuffix(role, "_constraints")
		role = strings.TrimSuffix(role, "_policy")

		// Read file content
		filePath := filepath.Join(acl.basePath, name)
		content, err := os.ReadFile(filePath)
		if err != nil {
			fmt.Printf("[AgentConstraintsLoader] Warning: failed to read %s: %v\n", filePath, err)
			continue
		}

		result[role] = string(content)

		// Also cache it
		acl.mutex.Lock()
		acl.cache[role] = string(content)
		acl.mutex.Unlock()
	}

	return result, nil
}

// ClearCache clears all cached constraints
func (acl *AgentConstraintsLoader) ClearCache() {
	acl.mutex.Lock()
	defer acl.mutex.Unlock()
	acl.cache = make(map[string]string)
}

// Reload reloads constraints for a specific role, bypassing cache
func (acl *AgentConstraintsLoader) Reload(role string) (string, error) {
	normalizedRole := strings.ToLower(strings.TrimSpace(role))

	// Clear from cache
	acl.mutex.Lock()
	delete(acl.cache, normalizedRole)
	acl.mutex.Unlock()

	// Load fresh
	return acl.LoadForRole(role)
}
