package reliability

import "strings"

type Effect int

const (
	Allow Effect = iota
	Deny
	Shed
)

type Verdict int

const (
	VerdictClear Verdict = iota
	VerdictRevoked
	VerdictUnavailable
)

func DecideAccess(method, path string, verdict Verdict) Effect {
	if verdict == VerdictRevoked {
		return Deny
	}
	if verdict != VerdictUnavailable {
		return Allow
	}
	if isLoginOrRefresh(path) || isWrite(method) {
		return Shed
	}
	return Allow
}

func isWrite(method string) bool {
	switch strings.ToUpper(method) {
	case "POST", "PUT", "PATCH", "DELETE":
		return true
	default:
		return false
	}
}

func isLoginOrRefresh(path string) bool {
	return strings.HasPrefix(path, "/api/auth/login") || strings.HasPrefix(path, "/api/auth/refresh")
}
