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

func TestNormalizeLocalDateWithFractionalSeconds(t *testing.T) {
	in := []byte(`{"operationTime":"2026-10-22T08:52:11.123456"}`)
	out := string(normalizeLocalTimes(in))
	want := `{"operationTime":"2026-10-22T08:52:11.123456+08:00"}`
	if out != want {
		t.Fatalf("got %s", out)
	}
}
