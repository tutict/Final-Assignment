package config

import (
	"fmt"
	"log"
	"os"
	"time"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
	"gorm.io/gorm/schema"
)

// DB Global instance
var DB *gorm.DB

// InitDB 初始化 GORM 数据库连接（相当于 Spring @Configuration）
func InitDB() *gorm.DB {
	dsn := "root:root@tcp(127.0.0.1:3306)/cesi?charset=utf8mb4&parseTime=True&loc=Local"

	newLogger := logger.New(
		log.New(os.Stdout, "\r\n", log.LstdFlags),
		logger.Config{
			SlowThreshold:             time.Second, // 慢查询阈值
			LogLevel:                  logger.Info, // 日志级别
			IgnoreRecordNotFoundError: true,
			Colorful:                  true,
		},
	)

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{
		NamingStrategy: schema.NamingStrategy{
			SingularTable: true, // 表名不加 s
		},
		Logger: newLogger,
	})

	if err != nil {
		panic(fmt.Sprintf("❌ 连接数据库失败: %v", err))
	}

	sqlDB, _ := db.DB()
	sqlDB.SetMaxOpenConns(50)
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetConnMaxLifetime(time.Hour)

	DB = db
	fmt.Println("✅ 数据库连接成功")
	return db
}
