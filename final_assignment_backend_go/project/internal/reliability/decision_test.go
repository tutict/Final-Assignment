package reliability

import (
	"testing"
	"time"
)

func TestDecide(t *testing.T) {
	if Decide(false, "", "", "sha256:a", 0) != Insert {
		t.Fatal("insert")
	}
	if Decide(true, "SUCCESS", "sha256:a", "sha256:a", time.Second) != Replay {
		t.Fatal("replay")
	}
	if Decide(true, "SUCCESS", "sha256:a", "sha256:b", time.Second) != Conflict {
		t.Fatal("conflict")
	}
	if Decide(true, "SUCCESS", "DONE", "sha256:b", time.Second) != Replay {
		t.Fatal("legacy")
	}
	if Decide(true, "PROCESSING", "sha256:a", "sha256:a", 30*time.Second) != InProgress {
		t.Fatal("in progress")
	}
	if Decide(true, "PROCESSING", "sha256:a", "sha256:a", 2*time.Minute) != Retry {
		t.Fatal("stale")
	}
	if Decide(true, "FAILED", "boom", "sha256:a", time.Minute) != Retry {
		t.Fatal("failed")
	}
}