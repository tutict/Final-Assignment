package ai

import (
	"fmt"
	"strings"
)

// RoleResolver resolves user roles from request metadata
type RoleResolver struct {
	defaultRole string
}

// NewRoleResolver creates a new RoleResolver
func NewRoleResolver() *RoleResolver {
	return &RoleResolver{
		defaultRole: "DRIVER",
	}
}

// ResolveFromMetadata extracts and normalizes user roles from request metadata
func (rr *RoleResolver) ResolveFromMetadata(metadata map[string]any) []string {
	if metadata == nil {
		return []string{rr.defaultRole}
	}

	// Try to extract roles from various possible keys
	roles := rr.extractRoles(metadata)
	if len(roles) == 0 {
		return []string{rr.defaultRole}
	}

	// Normalize and deduplicate roles
	return rr.normalizeRoles(roles)
}

// extractRoles extracts roles from metadata using multiple strategies
func (rr *RoleResolver) extractRoles(metadata map[string]any) []string {
	var roles []string

	// Strategy 1: Direct "roles" field
	if rolesVal, ok := metadata["roles"]; ok {
		roles = append(roles, rr.parseRolesValue(rolesVal)...)
	}

	// Strategy 2: "role" field (singular)
	if roleVal, ok := metadata["role"]; ok {
		if roleStr, ok := roleVal.(string); ok && roleStr != "" {
			roles = append(roles, roleStr)
		}
	}

	// Strategy 3: JWT claims (nested)
	if claims, ok := metadata["claims"].(map[string]any); ok {
		if rolesVal, ok := claims["roles"]; ok {
			roles = append(roles, rr.parseRolesValue(rolesVal)...)
		}
		if roleVal, ok := claims["role"]; ok {
			if roleStr, ok := roleVal.(string); ok && roleStr != "" {
				roles = append(roles, roleStr)
			}
		}
	}

	// Strategy 4: User object
	if user, ok := metadata["user"].(map[string]any); ok {
		if rolesVal, ok := user["roles"]; ok {
			roles = append(roles, rr.parseRolesValue(rolesVal)...)
		}
	}

	return roles
}

// parseRolesValue converts various role representations to string slice
func (rr *RoleResolver) parseRolesValue(value any) []string {
	switch v := value.(type) {
	case string:
		// Single role as string
		if v != "" {
			return []string{v}
		}
	case []string:
		// Already a string slice
		return v
	case []any:
		// Convert interface slice to string slice
		result := make([]string, 0, len(v))
		for _, item := range v {
			if str, ok := item.(string); ok && str != "" {
				result = append(result, str)
			}
		}
		return result
	}
	return []string{}
}

// normalizeRoles normalizes role names and removes duplicates
func (rr *RoleResolver) normalizeRoles(roles []string) []string {
	seen := make(map[string]bool)
	result := make([]string, 0, len(roles))

	for _, role := range roles {
		// Normalize: uppercase and trim
		normalized := strings.ToUpper(strings.TrimSpace(role))
		if normalized == "" {
			continue
		}

		// Deduplicate
		if seen[normalized] {
			continue
		}
		seen[normalized] = true

		result = append(result, normalized)
	}

	return result
}

// GetHighestPriorityRole returns the highest priority role from a list
func (rr *RoleResolver) GetHighestPriorityRole(roles []string) string {
	if len(roles) == 0 {
		return rr.defaultRole
	}

	// Define role priority (higher = more privileged)
	priority := map[string]int{
		"SUPER_ADMIN": 100,
		"ADMIN":       50,
		"MODERATOR":   30,
		"MANAGER":     25,
		"DRIVER":      10,
		"USER":        5,
	}

	highestRole := rr.defaultRole
	highestPriority := priority[highestRole]

	for _, role := range roles {
		normalized := strings.ToUpper(strings.TrimSpace(role))
		if p, exists := priority[normalized]; exists && p > highestPriority {
			highestRole = normalized
			highestPriority = p
		}
	}

	return highestRole
}

// HasRole checks if a specific role is present in the roles list
func (rr *RoleResolver) HasRole(roles []string, targetRole string) bool {
	targetNormalized := strings.ToUpper(strings.TrimSpace(targetRole))
	for _, role := range roles {
		if strings.ToUpper(strings.TrimSpace(role)) == targetNormalized {
			return true
		}
	}
	return false
}

// HasAnyRole checks if any of the target roles are present
func (rr *RoleResolver) HasAnyRole(roles []string, targetRoles []string) bool {
	for _, target := range targetRoles {
		if rr.HasRole(roles, target) {
			return true
		}
	}
	return false
}

// ValidateRole checks if a role is valid
func (rr *RoleResolver) ValidateRole(role string) error {
	normalized := strings.ToUpper(strings.TrimSpace(role))
	if normalized == "" {
		return fmt.Errorf("role cannot be empty")
	}

	// Valid roles (extend as needed)
	validRoles := []string{
		"SUPER_ADMIN", "ADMIN", "MODERATOR", "MANAGER", "DRIVER", "USER",
	}

	for _, valid := range validRoles {
		if normalized == valid {
			return nil
		}
	}

	return fmt.Errorf("invalid role: %s (valid roles: %s)", role, strings.Join(validRoles, ", "))
}

// SetDefaultRole sets the default role for users without explicit roles
func (rr *RoleResolver) SetDefaultRole(role string) {
	rr.defaultRole = strings.ToUpper(strings.TrimSpace(role))
}
