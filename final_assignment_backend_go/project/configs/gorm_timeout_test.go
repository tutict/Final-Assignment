package config

import (
	"context"
	"database/sql/driver"
	"errors"
	"strings"
	"testing"
)

type timeoutConn struct {
	query  string
	closed bool
	fail   bool
}

func (c *timeoutConn) Prepare(string) (driver.Stmt, error) { return nil, errors.New("unused") }
func (c *timeoutConn) Close() error                        { c.closed = true; return nil }
func (c *timeoutConn) Begin() (driver.Tx, error)           { return nil, errors.New("unused") }
func (c *timeoutConn) ExecContext(_ context.Context, query string, _ []driver.NamedValue) (driver.Result, error) {
	c.query = query
	if c.fail {
		return nil, errors.New("set failed")
	}
	return driver.RowsAffected(0), nil
}

type timeoutConnector struct{ conn *timeoutConn }

func (c timeoutConnector) Connect(context.Context) (driver.Conn, error) { return c.conn, nil }
func (c timeoutConnector) Driver() driver.Driver                        { return nil }

func TestSessionConnectorSetsStatementTimeout(t *testing.T) {
	conn := &timeoutConn{}
	got, err := (sessionConnector{base: timeoutConnector{conn: conn}}).Connect(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if got != conn {
		t.Fatal("returned a different connection")
	}
	if conn.query != statementTimeoutSQL {
		t.Fatalf("query = %q", conn.query)
	}
	if conn.closed {
		t.Fatal("connection closed after success")
	}
}

func TestSessionConnectorClosesWhenTimeoutCannotBeSet(t *testing.T) {
	conn := &timeoutConn{fail: true}
	_, err := (sessionConnector{base: timeoutConnector{conn: conn}}).Connect(context.Background())
	if err == nil {
		t.Fatal("expected error")
	}
	if !conn.closed {
		t.Fatal("connection left open")
	}
}

func TestDefaultDatabaseIsSharedTraffic(t *testing.T) {
	t.Setenv("MYSQL_DATABASE", "")
	t.Setenv("MYSQL_USER", "")
	t.Setenv("MYSQL_PASSWORD", "")
	t.Setenv("DB_PASSWORD", "")
	t.Setenv("SPRING_DATASOURCE_PASSWORD", "")
	t.Setenv("MYSQL_HOST", "")
	t.Setenv("MYSQL_PORT", "")
	dsn := defaultDSN()
	if !strings.Contains(dsn, "/traffic?") {
		t.Fatalf("dsn=%s", dsn)
	}
	for _, part := range []string{"timeout=200ms", "readTimeout=3s", "writeTimeout=3s"} {
		if !strings.Contains(dsn, part) {
			t.Fatalf("dsn=%s missing %s", dsn, part)
		}
	}
}

func TestOpenGormWithStatementTimeoutSetsMaxExecutionTime(t *testing.T) {
	db, err := OpenGormWithStatementTimeout("root:root@tcp(127.0.0.1:3306)/traffic?parseTime=true&charset=utf8mb4&loc=Local")
	if err != nil {
		t.Fatal(err)
	}
	sqlDB, err := db.DB()
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = sqlDB.Close() })
	var value int
	if err := db.Raw("SELECT @@SESSION.max_execution_time").Scan(&value).Error; err != nil {
		t.Fatal(err)
	}
	if value != 3000 {
		t.Fatalf("max_execution_time=%d", value)
	}
}
