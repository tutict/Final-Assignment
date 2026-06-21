package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"final_assignment_backend_go/project/configs/docker"
	redisconfig "final_assignment_backend_go/project/configs/redis"
	"final_assignment_backend_go/project/global_exception"
	"final_assignment_backend_go/project/internal/ai"
	"final_assignment_backend_go/project/internal/auth"
	"final_assignment_backend_go/project/internal/config"
	"final_assignment_backend_go/project/internal/handler"
	"final_assignment_backend_go/project/internal/provider"
	"final_assignment_backend_go/project/internal/service"
	gozeroconfig "final_assignment_backend_go/project/internal/gozero/config"
	gozerorag "final_assignment_backend_go/project/internal/gozero/rag"

	"github.com/gin-gonic/gin"
	"github.com/zeromicro/go-zero/core/conf"
)

// main 是项目的启动入口，初始化并运行 Gin Web 服务器
func main() {
	// 初始化 Gin 路由器
	router := gin.Default()

	// 注册全局异常处理器
	router.Use(global_exception.GlobalExceptionHandler())

	// 注册docker-container配置
	runner := docker.NewRunDocker()
	runner.Init()

	// 注册Redis配置
	redisCfg := redisconfig.NewRedisConfig()
	if err := redisCfg.InitRedis(); err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}

	// 加载 go-zero 配置文件
	var gozeroConf gozeroconfig.Config
	configFile := "project/etc/gozero-api.yaml"
	conf.MustLoad(configFile, &gozeroConf)

	// 初始化 RAG Runtime
	ragRuntime, err := gozerorag.NewRuntime(gozeroConf.Rag)
	if err != nil {
		log.Printf("[WARNING] Failed to initialize RAG runtime: %v", err)
		ragRuntime = gozerorag.DisabledRuntime()
	}
	defer ragRuntime.Close()

	// 加载 AI Chat 配置
	aiChatConfig := config.LoadFromEnv()

	// 初始化 AI Provider
	providerFactory := provider.NewFactory(aiChatConfig)
	aiProvider, err := providerFactory.CreateProvider()
	if err != nil {
		log.Fatalf("Failed to initialize AI provider: %v", err)
	}

	// 将 RAG Runtime 转换为 AiChatRagQuerier
	var ragQuerier service.AiChatRagQuerier
	if ragRuntime.Enabled && ragRuntime.Query != nil {
		ragQuerier = ragRuntime.Query
	}

	// 转换配置 - 使用默认值
	chatServiceConfig := service.AiChatConfig{
		StreamingEnabled:          true,
		ProviderPrimary:           aiChatConfig.ProviderType,
		ProviderTimeout:           30 * time.Second,
		ProviderStreamingTimeout:  2 * time.Minute,
		ProviderRetryAttempts:     3,
		KeepaliveInterval:         aiChatConfig.StreamKeepaliveInterval,
		PromptContextTokenBudget:  aiChatConfig.RAGTokenBudget,
		MockDelay:                 100 * time.Millisecond,
		OllamaEnabled:             aiChatConfig.ProviderType == "ollama",
		OllamaBaseURL:             aiChatConfig.ProviderURL,
		OllamaChatModel:           aiChatConfig.ProviderModel,
		OpenAICompatibleEnabled:   aiChatConfig.ProviderType == "openai",
		OpenAICompatibleAPIKey:    aiChatConfig.ProviderAPIKey,
		OpenAICompatibleChatModel: aiChatConfig.ProviderModel,
	}

	// 初始化 Chat Pipeline
	chatPipeline, err := ai.NewChatPipeline(ragQuerier, aiProvider, chatServiceConfig)
	if err != nil {
		log.Fatalf("Failed to initialize chat pipeline: %v", err)
	}

	// 初始化 WebSocket Ticket Service (30秒过期时间)
	wsTicketService := auth.NewWsTicketService(30 * time.Second)

	// 注册 AI Chat 路由
	aiChatHandler := handler.NewAiChatHandler(chatPipeline)
	handler.RegisterAiChatRoutes(router, aiChatHandler)

	// 注册 WebSocket Ticket 路由
	wsTicketHandler := handler.NewWsTicketHandler(wsTicketService)
	router.POST("/api/ws-ticket", wsTicketHandler.IssueTicket)
	router.GET("/api/ws-ticket/validate", wsTicketHandler.ValidateTicket)
	router.GET("/api/ws-ticket/stats", wsTicketHandler.GetStats)

	// 注册 RAG 查询路由
	router.POST("/api/rag/query", ragQueryHandler(ragRuntime))

	// 创建 HTTP 服务器
	server := &http.Server{
		Addr:    ":8081", // 监听端口
		Handler: router,
	}

	// 在 goroutine 中启动服务器
	go func() {
		log.Println("[INFO] Server started on http://localhost:8081")
		log.Println("[INFO] Endpoints:")
		log.Println("[INFO]   - POST /api/ai/chat/stream")
		log.Println("[INFO]   - POST /api/ws-ticket")
		log.Println("[INFO]   - POST /api/rag/query")
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
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

	// 停止 Docker 容器
	log.Println("Stopping Docker containers...")
	runner.StopContainers()

	log.Println("Server stopped")
}

// ragQueryHandler 处理 RAG 查询请求
func ragQueryHandler(runtime *gozerorag.Runtime) gin.HandlerFunc {
	return func(c *gin.Context) {
		var request service.RagQueryRequest
		if err := c.ShouldBindJSON(&request); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   "Invalid request format: " + err.Error(),
			})
			return
		}

		if runtime == nil || !runtime.Enabled || runtime.Query == nil {
			c.JSON(http.StatusOK, service.RagQueryResponse{
				Results: []service.RagRetrievalResult{},
			})
			return
		}

		result, err := runtime.Query.Query(c.Request.Context(), request)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   err.Error(),
			})
			return
		}

		c.JSON(http.StatusOK, result)
	}
}

