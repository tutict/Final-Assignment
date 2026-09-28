package reliability

import "testing"

func TestModelBulkheadRejectsThirdInFlight(t *testing.T) {
	gate := NewModelBulkhead(2)
	if !gate.TryAcquire() || !gate.TryAcquire() {
		t.Fatal("expected two in-flight permits")
	}
	if gate.TryAcquire() {
		t.Fatal("third model call must degrade immediately")
	}
	gate.Release()
	if !gate.TryAcquire() {
		t.Fatal("release should free one permit")
	}
}
