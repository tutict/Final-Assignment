package main

import (
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
)

// main 是项目的启动入口，初始化并运行 Gin Web 服务器
func main() {
	// 初始化 Gin 路由器
	router := gin.Default()

	// 注册路由
	//router.GET("/example", handler.ExampleHandler)

	// 创建 HTTP 服务器
	server := &http.Server{
		Addr:    ":8080", // 监听端口
		Handler: router,
	}

	// 在 goroutine 中启动服务器
	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// 优雅关闭：监听系统信号以关闭服务器
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")

	// 关闭服务器
	if err := server.Close(); err != nil {
		log.Fatalf("Server close error: %v", err)
	}
	log.Println("Server stopped")
}
