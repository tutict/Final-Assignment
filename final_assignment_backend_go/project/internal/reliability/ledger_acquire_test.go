package reliability

import (
	"context"
	"database/sql"
	"errors"
	"testing"
	"time"

	"gorm.io/gorm"
	"gorm.io/gorm/callbacks"
	"gorm.io/gorm/clause"
	"gorm.io/gorm/schema"
)

func TestLedgerAcquireTimeoutAbortsTheWrite(t *testing.T) {
	db, err := gorm.Open(fakeDialector{}, &gorm.Config{SkipDefaultTransaction: true})
	if err != nil {
		t.Fatal(err)
	}
	Install(db)
	Install(db)
	previous := acquireLedgerConn
	t.Cleanup(func() { acquireLedgerConn = previous })
	acquireLedgerConn = func(*gorm.DB) (*sql.Conn, error) {
		return nil, context.DeadlineExceeded
	}

	err = Ledger(db).Create(&RequestHistory{IdempotencyKey: "pool-wait", BusinessStatus: "PROCESSING"}).Error
	if !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("ledger write err=%v", err)
	}

	called := false
	acquireLedgerConn = func(*gorm.DB) (*sql.Conn, error) {
		called = true
		return nil, context.DeadlineExceeded
	}
	_ = db.Session(&gorm.Session{DryRun: true, SkipDefaultTransaction: true}).Create(&RequestHistory{IdempotencyKey: "plain"}).Error
	if called {
		t.Fatal("non-ledger statement borrowed a connection")
	}
}

func TestLedgerAcquireTimeoutIs200ms(t *testing.T) {
	if LedgerAcquireTimeout != 200*time.Millisecond {
		t.Fatalf("acquire=%s", LedgerAcquireTimeout)
	}
}

type fakeDialector struct{}

func (fakeDialector) Name() string { return "fake" }

func (fakeDialector) Initialize(db *gorm.DB) error {
	db.ConnPool = rejectPool{}
	callbacks.RegisterDefaultCallbacks(db, &callbacks.Config{})
	return nil
}

func (fakeDialector) Migrator(*gorm.DB) gorm.Migrator { return nil }

func (fakeDialector) DataTypeOf(*schema.Field) string { return "text" }

func (fakeDialector) DefaultValueOf(*schema.Field) clause.Expression { return clause.Expr{SQL: "NULL"} }

func (fakeDialector) BindVarTo(writer clause.Writer, _ *gorm.Statement, _ interface{}) {
	_, _ = writer.WriteString("?")
}

func (fakeDialector) QuoteTo(writer clause.Writer, value string) {
	_, _ = writer.WriteString(value)
}

func (fakeDialector) Explain(sql string, _ ...interface{}) string { return sql }

type rejectPool struct{}

func (rejectPool) PrepareContext(context.Context, string) (*sql.Stmt, error) {
	return nil, errors.New("pool should not be used")
}

func (rejectPool) ExecContext(context.Context, string, ...interface{}) (sql.Result, error) {
	return nil, errors.New("pool should not be used")
}

func (rejectPool) QueryContext(context.Context, string, ...interface{}) (*sql.Rows, error) {
	return nil, errors.New("pool should not be used")
}

func (rejectPool) QueryRowContext(context.Context, string, ...interface{}) *sql.Row {
	return nil
}
