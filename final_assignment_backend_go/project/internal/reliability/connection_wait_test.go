package reliability

import (
	"context"
	"errors"
	"testing"
)

func TestConnectionWaitRecognizesPoolAndDialFailures(t *testing.T) {
	if !ConnectionWait(context.DeadlineExceeded) {
		t.Fatal("deadline")
	}
	if !ConnectionWait(errors.New("dial tcp 127.0.0.1:3306: i/o timeout")) {
		t.Fatal("dial")
	}
	if !ConnectionWait(errors.New("wrapped: driver: bad connection")) {
		t.Fatal("bad connection")
	}
	if !ConnectionWait(errors.New("Error 1213 (40001): Deadlock found when trying to get lock")) {
		t.Fatal("deadlock")
	}
	if !ConnectionWait(errors.New("Error 1205 (HY000): Lock wait timeout exceeded")) {
		t.Fatal("lock wait")
	}
	if ConnectionWait(errors.New("duplicate fine number")) {
		t.Fatal("business error")
	}
}
