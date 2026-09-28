package reliability

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"testing"
	"time"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var errNonLedgerBegin = errors.New("non-ledger begin")

type scriptedSource struct {
	connCalls  int
	beginCalls int
}

func (s *scriptedSource) Conn(ctx context.Context) (*sql.Conn, error) {
	s.connCalls++
	<-ctx.Done()
	return nil, ctx.Err()
}

func (s *scriptedSource) BeginTx(context.Context, *sql.TxOptions) (*sql.Tx, error) {
	s.beginCalls++
	return nil, errNonLedgerBegin
}

func (s *scriptedSource) PrepareContext(context.Context, string) (*sql.Stmt, error) {
	return nil, errors.New("unused")
}

func (s *scriptedSource) ExecContext(context.Context, string, ...any) (sql.Result, error) {
	return nil, errors.New("unused")
}

func (s *scriptedSource) QueryContext(context.Context, string, ...any) (*sql.Rows, error) {
	return nil, errors.New("unused")
}

func (s *scriptedSource) QueryRowContext(context.Context, string, ...any) *sql.Row {
	return nil
}

func TestLedgerBeginWaitsAtMost200ms(t *testing.T) {
	db, err := gorm.Open(fakeDialector{}, &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	Install(db)
	source := &scriptedSource{}
	pool := &ledgerPool{inner: source}
	db.ConnPool = pool
	db.Statement.ConnPool = pool

	started := time.Now()
	err = Ledger(db).Create(&RequestHistory{IdempotencyKey: "tx-wait", BusinessStatus: "PROCESSING"}).Error
	elapsed := time.Since(started)
	if !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("err=%v elapsed=%s connCalls=%d", err, elapsed, source.connCalls)
	}
	if source.connCalls != 1 {
		t.Fatalf("connCalls=%d", source.connCalls)
	}
	if elapsed < 100*time.Millisecond || elapsed > 800*time.Millisecond {
		t.Fatalf("elapsed=%s", elapsed)
	}
}

func TestNonLedgerBeginDoesNotUseTheAcquireTimeout(t *testing.T) {
	db, err := gorm.Open(fakeDialector{}, &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	Install(db)
	source := &scriptedSource{}
	pool := &ledgerPool{inner: source}
	db.ConnPool = pool
	db.Statement.ConnPool = pool

	started := time.Now()
	err = db.Create(&RequestHistory{IdempotencyKey: "plain", BusinessStatus: "PROCESSING"}).Error
	elapsed := time.Since(started)
	if !errors.Is(err, errNonLedgerBegin) {
		t.Fatalf("err=%v", err)
	}
	if source.connCalls != 0 || source.beginCalls != 1 {
		t.Fatalf("conn=%d begin=%d", source.connCalls, source.beginCalls)
	}
	if elapsed > 100*time.Millisecond {
		t.Fatalf("elapsed=%s", elapsed)
	}
}

func TestLedgerPoolCommitsAndReturnsTheConnection(t *testing.T) {
	raw, err := sql.Open("mysql", "root:root@tcp(127.0.0.1:3306)/traffic?parseTime=true&charset=utf8mb4&loc=Local&timeout=2s")
	if err != nil {
		t.Fatal(err)
	}
	raw.SetMaxOpenConns(4)
	raw.SetMaxIdleConns(2)
	if err = raw.Ping(); err != nil {
		t.Skip(err)
	}
	t.Cleanup(func() { _ = raw.Close() })

	db, err := gorm.Open(mysql.New(mysql.Config{Conn: NewLedgerPool(raw), SkipInitializeWithVersion: true}), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	Install(db)
	got, err := db.DB()
	if err != nil || got != raw {
		t.Fatalf("underlying db=%v err=%v", got, err)
	}

	key := fmt.Sprintf("pool-commit-%d", time.Now().UnixNano())
	t.Cleanup(func() {
		_ = db.Where("idempotency_key = ?", key).Delete(&RequestHistory{}).Error
	})
	row := RequestHistory{
		IdempotencyKey: key,
		RequestMethod:  "POST",
		RequestURL:     "/api/payments",
		RequestParams:  "sha256:pool",
		BusinessType:   "PAYMENT_CREATE",
		BusinessStatus: "PROCESSING",
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}
	if err = Ledger(db).Create(&row).Error; err != nil {
		t.Fatal(err)
	}
	if row.ID == 0 {
		t.Fatal("id was not assigned")
	}
	var loaded RequestHistory
	if err = db.Where("idempotency_key = ?", key).First(&loaded).Error; err != nil {
		t.Fatal(err)
	}
	if loaded.BusinessStatus != "PROCESSING" {
		t.Fatalf("status=%s", loaded.BusinessStatus)
	}
	stats := raw.Stats()
	if stats.InUse != 0 {
		t.Fatalf("in use=%d open=%d", stats.InUse, stats.OpenConnections)
	}
}
