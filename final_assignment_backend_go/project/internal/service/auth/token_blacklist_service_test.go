package auth

import (
	"testing"

	"final_assignment_backend_go/project/internal/reliability"
)

func TestLocalTokenBlacklistServiceWithoutRedis(t *testing.T) {
	service := NewLocalTokenBlacklistService()
	if !service.Reachable() {
		t.Fatal("local-only blacklist must report reachable")
	}
	if got := service.Inspect("token-a"); got != reliability.VerdictClear {
		t.Fatalf("fresh token verdict = %v, want clear", got)
	}
	if err := service.Blacklist("token-a", 60_000); err != nil {
		t.Fatalf("blacklist without redis: %v", err)
	}
	if got := service.Inspect("token-a"); got != reliability.VerdictRevoked {
		t.Fatalf("revoked token verdict = %v, want revoked", got)
	}
	if got := service.Inspect("token-b"); got != reliability.VerdictClear {
		t.Fatalf("other token verdict = %v, want clear", got)
	}
}
