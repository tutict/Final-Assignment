package handler

import "testing"

func TestNormalizeLocalDate(t *testing.T) {
	in := []byte(`{"fineDate":"2026-09-30","offenseTime":"2026-09-30T10:00:00","birthdate":"1992-03-03"}`)
	out := string(normalizeLocalTimes(in))
	want := `{"fineDate":"2026-09-30T00:00:00+08:00","offenseTime":"2026-09-30T10:00:00+08:00","birthdate":"1992-03-03T00:00:00+08:00"}`
	if out != want {
		t.Fatalf("got %s", out)
	}
}
