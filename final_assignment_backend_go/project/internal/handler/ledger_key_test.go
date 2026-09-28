package handler

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/reliability"
)

func TestRequireIdempotencyKeyRejectsMissingHeader(t *testing.T) {
	gin.SetMode(gin.TestMode)
	rec := httptest.NewRecorder()
	ctx, _ := gin.CreateTestContext(rec)
	ctx.Request = httptest.NewRequest(http.MethodPost, "/api/fines", nil)
	if _, ok := requireIdempotencyKey(ctx); ok {
		t.Fatal("missing header was accepted")
	}
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status=%d", rec.Code)
	}
}

func TestWriteLedgerErrorMapsReplayAndConflict(t *testing.T) {
	gin.SetMode(gin.TestMode)
	rec := httptest.NewRecorder()
	ctx, _ := gin.CreateTestContext(rec)
	ctx.Request = httptest.NewRequest(http.MethodPost, "/api/appeals", nil)
	writeLedgerError(ctx, reliability.ErrReplay)
	if rec.Code != http.StatusAlreadyReported {
		t.Fatalf("replay status=%d", rec.Code)
	}
	rec = httptest.NewRecorder()
	ctx, _ = gin.CreateTestContext(rec)
	ctx.Request = httptest.NewRequest(http.MethodPost, "/api/appeals", nil)
	writeLedgerError(ctx, reliability.ErrConflict)
	if rec.Code != http.StatusConflict {
		t.Fatalf("conflict status=%d", rec.Code)
	}
	if errors.Is(reliability.ErrKeyRequired, reliability.ErrConflict) {
		t.Fatal("errors collapsed")
	}
}

func TestWriteLedgerErrorMapsConnectionWait(t *testing.T) {
	gin.SetMode(gin.TestMode)
	rec := httptest.NewRecorder()
	ctx, _ := gin.CreateTestContext(rec)
	ctx.Request = httptest.NewRequest(http.MethodPost, "/api/payments", nil)
	writeLedgerError(ctx, errors.New("dial tcp 127.0.0.1:3306: i/o timeout"))
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status=%d", rec.Code)
	}
	if rec.Header().Get("Retry-After") != "1" {
		t.Fatalf("retry=%q", rec.Header().Get("Retry-After"))
	}
}
