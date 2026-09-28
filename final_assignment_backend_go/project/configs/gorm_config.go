package config

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/reliability"
	mysqldriver "github.com/go-sql-driver/mysql"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
	"gorm.io/gorm/schema"
)

// DB Global instance
var DB *gorm.DB

func getenvDefault(key, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	return value
}

// InitDB 初始化 GORM 数据库连接（相当于 Spring @Configuration）
func InitDB() *gorm.DB {
	dsn := strings.TrimSpace(os.Getenv("MYSQL_DSN"))
	if dsn == "" {
		dsn = defaultDSN()
	}

	newLogger := logger.New(
		log.New(os.Stdout, "\r\n", log.LstdFlags),
		logger.Config{
			SlowThreshold:             time.Second,
			LogLevel:                  logger.Info,
			IgnoreRecordNotFoundError: true,
			Colorful:                  true,
		},
	)

	db, err := openMySQL(dsn, newLogger)
	if err != nil {
		panic(fmt.Sprintf("连接数据库失败: %v", err))
	}

	DB = db
	fmt.Println("数据库连接成功")
	return db
}

const statementTimeoutSQL = "SET SESSION max_execution_time=3000"

func defaultDSN() string {
	user := getenvDefault("MYSQL_USER", "root")
	pass := getenvDefault("MYSQL_PASSWORD", getenvDefault("DB_PASSWORD", getenvDefault("SPRING_DATASOURCE_PASSWORD", "root")))
	host := getenvDefault("MYSQL_HOST", "127.0.0.1")
	port := getenvDefault("MYSQL_PORT", "3306")
	name := getenvDefault("MYSQL_DATABASE", "traffic")
	return user + ":" + pass + "@tcp(" + host + ":" + port + ")/" + name + "?charset=utf8mb4&parseTime=True&loc=Local&timeout=200ms&readTimeout=3s&writeTimeout=3s"
}
func openMySQL(dsn string, queryLogger logger.Interface) (*gorm.DB, error) {
	parsed, err := mysqldriver.ParseDSN(dsn)
	if err != nil {
		return nil, err
	}
	connector, err := mysqldriver.NewConnector(parsed)
	if err != nil {
		return nil, err
	}
	sqlDB := sql.OpenDB(sessionConnector{base: connector})
	sqlDB.SetMaxOpenConns(50)
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetConnMaxLifetime(time.Hour)
	db, err := gorm.Open(mysql.New(mysql.Config{Conn: reliability.NewLedgerPool(sqlDB)}), &gorm.Config{
		NamingStrategy: schema.NamingStrategy{SingularTable: true},
		Logger:         queryLogger,
	})
	if err != nil {
		return nil, err
	}
	reliability.Install(db)
	return db, nil
}

type sessionConnector struct {
	base driver.Connector
}

func (s sessionConnector) Connect(ctx context.Context) (driver.Conn, error) {
	conn, err := s.base.Connect(ctx)
	if err != nil {
		return nil, err
	}
	execer, ok := conn.(driver.ExecerContext)
	if !ok {
		_ = conn.Close()
		return nil, fmt.Errorf("mysql connection cannot set max_execution_time")
	}
	if _, err = execer.ExecContext(ctx, statementTimeoutSQL, nil); err != nil {
		_ = conn.Close()
		return nil, err
	}
	return conn, nil
}

func (s sessionConnector) Driver() driver.Driver {
	return s.base.Driver()
}

// OpenGormWithStatementTimeout opens MySQL and sets max_execution_time=3000 on every new session.
func OpenGormWithStatementTimeout(dsn string) (*gorm.DB, error) {
	parsed, err := mysqldriver.ParseDSN(dsn)
	if err != nil {
		return nil, err
	}
	connector, err := mysqldriver.NewConnector(parsed)
	if err != nil {
		return nil, err
	}
	sqlDB := sql.OpenDB(sessionConnector{base: connector})
	db, err := gorm.Open(mysql.New(mysql.Config{Conn: sqlDB}), &gorm.Config{})
	if err != nil {
		_ = sqlDB.Close()
		return nil, err
	}
	return db, nil
}
