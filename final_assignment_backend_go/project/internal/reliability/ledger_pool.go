package reliability

import (
	"context"
	"database/sql"
	"sync"

	"gorm.io/gorm"
)

type sqlPool interface {
	BeginTx(ctx context.Context, opts *sql.TxOptions) (*sql.Tx, error)
	Conn(ctx context.Context) (*sql.Conn, error)
	PrepareContext(ctx context.Context, query string) (*sql.Stmt, error)
	ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
	QueryContext(ctx context.Context, query string, args ...any) (*sql.Rows, error)
	QueryRowContext(ctx context.Context, query string, args ...any) *sql.Row
}

// NewLedgerPool bounds only the connection borrow for a ledger transaction.
// The transaction context itself is not cancelled at 200ms, so a write that
// already has a connection can still run until the statement cap.
func NewLedgerPool(db *sql.DB) gorm.ConnPool {
	return &ledgerPool{inner: db}
}

type ledgerPool struct {
	inner sqlPool
}

func (p *ledgerPool) BeginTx(ctx context.Context, opts *sql.TxOptions) (gorm.ConnPool, error) {
	if ctx == nil {
		ctx = context.Background()
	}
	if !IsLedger(ctx) {
		tx, err := p.inner.BeginTx(ctx, opts)
		if err != nil {
			return nil, err
		}
		return tx, nil
	}
	acquireCtx, cancel := context.WithTimeout(ctx, LedgerAcquireTimeout)
	conn, err := p.inner.Conn(acquireCtx)
	cancel()
	if err != nil {
		return nil, err
	}
	tx, err := conn.BeginTx(ctx, opts)
	if err != nil {
		_ = conn.Close()
		return nil, err
	}
	return &releasingTx{Tx: tx, conn: conn}, nil
}

func (p *ledgerPool) PrepareContext(ctx context.Context, query string) (*sql.Stmt, error) {
	return p.inner.PrepareContext(ctx, query)
}

func (p *ledgerPool) ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error) {
	return p.inner.ExecContext(ctx, query, args...)
}

func (p *ledgerPool) QueryContext(ctx context.Context, query string, args ...any) (*sql.Rows, error) {
	return p.inner.QueryContext(ctx, query, args...)
}

func (p *ledgerPool) QueryRowContext(ctx context.Context, query string, args ...any) *sql.Row {
	return p.inner.QueryRowContext(ctx, query, args...)
}

func (p *ledgerPool) GetDBConn() (*sql.DB, error) {
	db, ok := p.inner.(*sql.DB)
	if !ok || db == nil {
		return nil, gorm.ErrInvalidDB
	}
	return db, nil
}

type releasingTx struct {
	*sql.Tx
	conn *sql.Conn
	once sync.Once
}

func (t *releasingTx) Commit() error {
	err := t.Tx.Commit()
	t.release()
	return err
}

func (t *releasingTx) Rollback() error {
	err := t.Tx.Rollback()
	t.release()
	return err
}

func (t *releasingTx) release() {
	t.once.Do(func() {
		if t.conn != nil {
			_ = t.conn.Close()
		}
	})
}
