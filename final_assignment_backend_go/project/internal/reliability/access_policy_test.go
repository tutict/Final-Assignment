package reliability

import "testing"

func TestDecideAccess(t *testing.T) {
	if DecideAccess("GET", "/api/offenses/1", VerdictUnavailable) != Allow {
		t.Fatal("get")
	}
	if DecideAccess("POST", "/api/payments", VerdictUnavailable) != Shed {
		t.Fatal("write")
	}
	if DecideAccess("POST", "/api/auth/login", VerdictUnavailable) != Shed {
		t.Fatal("login")
	}
	if DecideAccess("GET", "/api/offenses/1", VerdictRevoked) != Deny {
		t.Fatal("revoked")
	}
}
