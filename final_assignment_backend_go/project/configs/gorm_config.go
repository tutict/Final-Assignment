package config

import (
	"fmt"
	"log"
	"os"
	"strings"
	"time"

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
		user := getenvDefault("MYSQL_USER", "root")
		pass := getenvDefault("MYSQL_PASSWORD", getenvDefault("DB_PASSWORD", getenvDefault("SPRING_DATASOURCE_PASSWORD", "root")))
		host := getenvDefault("MYSQL_HOST", "127.0.0.1")
		port := getenvDefault("MYSQL_PORT", "3306")
		name := getenvDefault("MYSQL_DATABASE", "cesi")
		dsn = user + ":" + pass + "@tcp(" + host + ":" + port + ")/" + name + "?charset=utf8mb4&parseTime=True&loc=Local"
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

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{
		NamingStrategy: schema.NamingStrategy{
			SingularTable: true,
		},
		Logger: newLogger,
	})

	if err != nil {
		panic(fmt.Sprintf("连接数据库失败: %v", err))
	}

	sqlDB, _ := db.DB()
	sqlDB.SetMaxOpenConns(50)
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetConnMaxLifetime(time.Hour)

	DB = db
	fmt.Println("数据库连接成功")
	return db
}
