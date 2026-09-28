package reliability

import (
	"context"
	"database/sql"
	"time"

	"gorm.io/gorm"
)

const LedgerAcquireTimeout = 200 * time.Millisecond

const ledgerQueryTimeout = 3 * time.Second

type ledgerCtxKey struct{}

// acquireLedgerConn borrows one pooled connection. Tests replace it.
var acquireLedgerConn = func(db *gorm.DB) (*sql.Conn, error) {
	sqlDB, err := db.DB()
	if err != nil {
		return nil, err
	}
	ctx, cancel := context.WithTimeout(context.Background(), LedgerAcquireTimeout)
	defer cancel()
	return sqlDB.Conn(ctx)
}

// Ledger marks a session whose statements borrow a connection within 200ms.
// The borrowed connection then runs the statement for at most 3 seconds.
func Ledger(db *gorm.DB) *gorm.DB {
	if db == nil || db.Statement == nil || IsLedger(db.Statement.Context) {
		return db
	}
	ctx := db.Statement.Context
	if ctx == nil {
		ctx = context.Background()
	}
	return db.WithContext(context.WithValue(ctx, ledgerCtxKey{}, true))
}

func IsLedger(ctx context.Context) bool {
	if ctx == nil {
		return false
	}
	marked, _ := ctx.Value(ledgerCtxKey{}).(bool)
	return marked
}

// Install bounds ledger-marked statements to a 200ms pool borrow.
func Install(db *gorm.DB) {
	if db == nil {
		return
	}
	installCallback(db.Callback().Create(), "gorm:create", "create")
	installCallback(db.Callback().Query(), "gorm:query", "query")
	installCallback(db.Callback().Update(), "gorm:update", "update")
	installCallback(db.Callback().Delete(), "gorm:delete", "delete")
	installCallback(db.Callback().Raw(), "gorm:raw", "raw")
	installCallback(db.Callback().Row(), "gorm:row", "row")
}

func installCallback[C interface {
	Get(name string) func(*gorm.DB)
	Before(name string) R
	After(name string) R
}, R interface {
	Register(name string, fn func(*gorm.DB)) error
}](chain C, point, name string) {
	borrowName := "reliability:borrow:" + name
	releaseName := "reliability:release:" + name
	if chain.Get(borrowName) == nil {
		_ = chain.Before(point).Register(borrowName, borrowLedgerConn)
	}
	if chain.Get(releaseName) == nil {
		_ = chain.After(point).Register(releaseName, releaseLedgerConn)
	}
}

func borrowLedgerConn(db *gorm.DB) {
	if db == nil || db.Error != nil || db.Statement == nil || !IsLedger(db.Statement.Context) {
		return
	}
	if _, exists := db.InstanceGet("reliability:conn"); exists {
		return
	}
	// GORM's default transaction borrows first. That borrow is bounded by the
	// ledger pool, so do not take a second connection out of the transaction.
	if _, started := db.InstanceGet("gorm:started_transaction"); started {
		return
	}
	if _, isTx := db.Statement.ConnPool.(*sql.Tx); isTx {
		return
	}
	conn, err := acquireLedgerConn(db)
	if err != nil {
		_ = db.AddError(err)
		return
	}
	queryCtx, cancel := context.WithTimeout(context.Background(), ledgerQueryTimeout)
	db.InstanceSet("reliability:conn", conn)
	db.InstanceSet("reliability:cancel", cancel)
	db.InstanceSet("reliability:pool", db.Statement.ConnPool)
	db.InstanceSet("reliability:ctx", db.Statement.Context)
	db.Statement.ConnPool = conn
	db.Statement.Context = queryCtx
}

func releaseLedgerConn(db *gorm.DB) {
	if db == nil || db.Statement == nil {
		return
	}
	if pool, ok := db.InstanceGet("reliability:pool"); ok {
		if connPool, ok := pool.(gorm.ConnPool); ok {
			db.Statement.ConnPool = connPool
		}
	}
	if prev, ok := db.InstanceGet("reliability:ctx"); ok {
		if ctx, ok := prev.(context.Context); ok {
			db.Statement.Context = ctx
		}
	}
	if cancel, ok := db.InstanceGet("reliability:cancel"); ok {
		if fn, ok := cancel.(context.CancelFunc); ok {
			fn()
		}
	}
	if borrowed, ok := db.InstanceGet("reliability:conn"); ok {
		if conn, ok := borrowed.(*sql.Conn); ok && conn != nil {
			_ = conn.Close()
		}
	}
}
