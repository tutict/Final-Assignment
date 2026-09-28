package offense

import "testing"
import "time"

func TestDefaultScoringCycleFitsColumn(t *testing.T) {
	got := defaultScoringCycle(time.Date(2026, 9, 28, 0, 0, 0, 0, time.UTC))
	if got != "2026-2027" {
		t.Fatalf("cycle=%s", got)
	}
	if len([]rune(got)) > 20 {
		t.Fatalf("len=%d", len([]rune(got)))
	}
}
