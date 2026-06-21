package main

import (
	"context"
	"encoding/base64"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	config "final_assignment_backend_go/project/configs"
	authcfg "final_assignment_backend_go/project/configs/auth"
	"final_assignment_backend_go/project/configs/docker"
	redisconfig "final_assignment_backend_go/project/configs/redis"
	"final_assignment_backend_go/project/global_exception"
	"final_assignment_backend_go/project/internal/ai"
	"final_assignment_backend_go/project/internal/auth"
	aiconfig "final_assignment_backend_go/project/internal/config"
	"final_assignment_backend_go/project/internal/handler"
	"final_assignment_backend_go/project/internal/provider"
	"final_assignment_backend_go/project/internal/repo"
	"final_assignment_backend_go/project/internal/service"
	gozeroconfig "final_assignment_backend_go/project/internal/gozero/config"
	gozerorag "final_assignment_backend_go/project/internal/gozero/rag"

	"github.com/gin-gonic/gin"
	"github.com/zeromicro/go-zero/core/conf"
	"gorm.io/gorm"
)

func main() {
	// 初始化数据库
	db := config.InitDB()
	tokenProvider := initTokenProvider()

	// 初始化 Docker 容器
	runner := docker.NewRunDocker()
	runner.Init()

	// 初始化 Redis
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
	aiChatConfig := aiconfig.LoadFromEnv()

	// 初始化 AI Provider
	providerFactory := provider.NewFactory(aiChatConfig)
	aiProvider, err := providerFactory.CreateProvider()
	if err != nil {
		log.Printf("[WARNING] Failed to initialize AI provider: %v", err)
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
	var chatPipeline *ai.ChatPipeline
	if aiProvider != nil {
		chatPipeline, err = ai.NewChatPipeline(ragQuerier, aiProvider, chatServiceConfig)
		if err != nil {
			log.Printf("[WARNING] Failed to initialize chat pipeline: %v", err)
		}
	}

	// 初始化 WebSocket Ticket Service (30秒过期时间)
	wsTicketService := auth.NewWsTicketService(30 * time.Second)

	// 初始化用户和认证服务
	userService := service.NewUserManagementService(repo.NewUserManagementRepo(db))
	authService := service.NewAuthWsService(userService, tokenProvider)
	authHandler := handler.NewAuthHandler(authService)

	// 创建路由
	router := gin.Default()
	router.Use(global_exception.GlobalExceptionHandler())
	router.Use(optionalPrincipal(tokenProvider))

	// 公开路由
	router.GET("/api/actuator/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "UP"})
	})
	router.POST("/api/auth/login", authHandler.Login)
	router.POST("/api/auth/register", authHandler.RegisterUser)
	router.POST("/api/auth/refresh", authHandler.Refresh)

	// AI Chat 路由（如果已初始化）
	if chatPipeline != nil {
		aiChatHandler := handler.NewAiChatHandler(chatPipeline)
		handler.RegisterAiChatRoutes(router, aiChatHandler)
	}

	// WebSocket Ticket 路由
	router.POST("/api/ws-ticket", handler.NewWsTicketHandler(wsTicketService).IssueTicket)
	router.GET("/api/ws-ticket/validate", handler.NewWsTicketHandler(wsTicketService).ValidateTicket)
	router.GET("/api/ws-ticket/stats", handler.NewWsTicketHandler(wsTicketService).GetStats)

	// RAG 查询路由
	router.POST("/api/rag/query", ragQueryHandler(ragRuntime))

	// 需要认证的路由
	router.Use(requiredPrincipal(tokenProvider), accessPolicy())
	router.POST("/api/auth/logout", authHandler.Logout)
	router.GET("/api/auth/users", authHandler.GetAllUsers)
	registerRoutes(router, db, userService)

	// 创建 HTTP 服务器
	server := &http.Server{
		Addr:    ":" + envOrDefault("PORT", "8080"),
		Handler: router,
	}

	// 在 goroutine 中启动服务器
	go func() {
		log.Printf("[INFO] Go backend started on http://localhost%s", server.Addr)
		log.Println("[INFO] Available endpoints:")
		log.Println("[INFO]   - GET  /api/actuator/health")
		log.Println("[INFO]   - POST /api/auth/login")
		log.Println("[INFO]   - POST /api/auth/register")
		if chatPipeline != nil {
			log.Println("[INFO]   - POST /api/ai/chat/stream")
		}
		log.Println("[INFO]   - POST /api/ws-ticket")
		log.Println("[INFO]   - POST /api/rag/query")
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// 优雅关闭：监听系统信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")

	// 关闭服务器
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := server.Shutdown(ctx); err != nil {
		log.Printf("Server shutdown error: %v", err)
	}

	// 停止 Docker 容器
	log.Println("Stopping Docker containers...")
	runner.StopContainers()

	log.Println("Server stopped gracefully")
}

func registerRoutes(router *gin.Engine, gormDB *gorm.DB, userService *service.UserManagementService) {
	root := router.Group("")
	api := router.Group("/api")

	appealService := service.NewAppealManagementService(repo.NewAppealManagementRepo(gormDB))
	backupService := service.NewBackupRestoreService(repo.NewBackupRestoreRepo(gormDB))
	deductionService := service.NewDeductionInformationService(repo.NewDeductionInformationRepo(gormDB))
	driverService := service.NewDriverInformationService(repo.NewDriverInformationRepo(gormDB))
	fineService := service.NewFineInformationService(repo.NewFineInformationRepo(gormDB))
	loginLogService := service.NewLoginLogService(repo.NewLoginLogRepo(gormDB))
	offenseService := service.NewOffenseInformationService(repo.NewOffenseInformationRepo(gormDB))
	operationLogService := service.NewOperationLogService(repo.NewOperationLogRepo(gormDB))
	permissionService := service.NewPermissionManagementService(repo.NewPermissionManagementRepo(gormDB))
	progressService := service.NewProgressItemService(repo.NewProgressItemRepo(gormDB))
	roleService := service.NewRoleManagementService(repo.NewRoleManagementRepo(gormDB))
	systemLogsService := service.NewSystemLogsService(repo.NewSystemLogsRepo(gormDB))
	systemSettingsService := service.NewSystemSettingsService(repo.NewSystemSettingsRepo(gormDB))
	vehicleService := service.NewVehicleService(repo.NewVehicleInformationRepo(gormDB))
	trafficService := service.NewTrafficViolationService(gormDB)

	handler.NewUserManagementController(userService).RegisterRoutes(api)
	handler.NewBackupRestoreController(backupService).RegisterRoutes(router)
	handler.NewDeductionInformationController(deductionService).RegisterRoutes(router)
	handler.NewDriverInformationController(driverService, userService).RegisterRoutes(router)
	handler.NewLoginLogController(loginLogService).RegisterRoutes(router)
	handler.NewPermissionHandler(permissionService).RegisterRoutes(router)
	handler.NewProgressHandler(progressService).RegisterRoutes(router)
	handler.NewRoleManagementController(roleService).RegisterRoutes(router)
	handler.NewSystemLogsController(systemLogsService).RegisterRoutes(router)
	handler.NewSystemSettingsController(systemSettingsService).RegisterRoutes(router)
	handler.NewVehicleController(vehicleService).RegisterRoutes(router)
	(&handler.OffenseInformationController{Service: offenseService}).RegisterRoutes(root)
	(&handler.OperationLogController{Service: operationLogService}).RegisterRoutes(root)

	registerFineRoutes(router, handler.NewFineController(fineService))
	registerAppealRoutes(router, handler.NewAppealHandler(appealService))
	registerTrafficRoutes(router, handler.NewTrafficViolationHandler(trafficService))
}

func registerFineRoutes(router *gin.Engine, controller *handler.FineController) {
	group := router.Group("/api/fines")
	group.POST("", controller.CreateFine)
	group.GET("", controller.GetAllFines)
	group.GET("/payee/:payee", controller.GetFinesByPayee)
	group.GET("/timeRange", controller.GetFinesByTimeRange)
	group.GET("/receiptNumber/:receiptNumber", controller.GetFineByReceiptNumber)
	group.GET("/by-time-range", controller.SearchByFineTimeRange)
	group.GET("/:fineId", controller.GetFineByID)
	group.PUT("/:fineId", controller.UpdateFine)
	group.DELETE("/:fineId", controller.DeleteFine)
}

func registerAppealRoutes(router *gin.Engine, controller *handler.AppealHandler) {
	group := router.Group("/api/appeals")
	group.POST("", controller.CreateAppeal)
	group.GET("", controller.GetAllAppeals)
	group.GET("/status/:status", controller.GetAppealsByProcessStatus)
	group.GET("/name/:name", controller.GetAppealsByAppellantName)
	group.GET("/id-card/:idCard", controller.GetAppealsByIdCardNumber)
	group.GET("/contact/:number", controller.GetAppealsByContactNumber)
	group.GET("/offense/:offenseId", controller.GetAppealsByOffenseID)
	group.GET("/time-range", controller.GetAppealsByTimeRange)
	group.GET("/count/status/:status", controller.CountAppealsByStatus)
	group.GET("/:id/offense", controller.GetOffenseByAppealID)
	group.GET("/:id", controller.GetAppealByID)
	group.PUT("/:id", controller.UpdateAppeal)
	group.DELETE("/:id", controller.DeleteAppeal)
}

func registerTrafficRoutes(router *gin.Engine, controller *handler.TrafficViolationHandler) {
	group := router.Group("/api/traffic-violations")
	group.GET("/violation-types", controller.GetViolationTypeCounts)
	group.GET("/time-series", controller.GetTimeSeriesData)
	group.GET("/appeal-reasons", controller.GetAppealReasonCounts)
	group.GET("/fine-payment-status", controller.GetFinePaymentStatus)
}

func initTokenProvider() *authcfg.TokenProvider {
	secret := envOrDefault("JWT_SECRET", "final-assignment-dev-secret")
	encoded := secret
	if _, err := base64.StdEncoding.DecodeString(secret); err != nil {
		encoded = base64.StdEncoding.EncodeToString([]byte(secret))
	}
	provider := &authcfg.TokenProvider{}
	if err := provider.Init(encoded); err != nil {
		log.Fatalf("failed to initialize token provider: %v", err)
	}
	return provider
}

func optionalPrincipal(provider *authcfg.TokenProvider) gin.HandlerFunc {
	return func(c *gin.Context) {
		_, _ = attachPrincipal(c, provider)
		c.Next()
	}
}

func requiredPrincipal(provider *authcfg.TokenProvider) gin.HandlerFunc {
	return func(c *gin.Context) {
		if ok, err := attachPrincipal(c, provider); !ok {
			status := http.StatusUnauthorized
			message := "unauthorized"
			if err != nil {
				message = err.Error()
			}
			c.AbortWithStatusJSON(status, gin.H{"error": message})
			return
		}
		c.Next()
	}
}

func accessPolicy() gin.HandlerFunc {
	return func(c *gin.Context) {
		if requiresAdmin(c.Request.URL.Path) && !hasAnyRole(c, "ADMIN") {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "access denied"})
			return
		}
		c.Next()
	}
}

func attachPrincipal(c *gin.Context, provider *authcfg.TokenProvider) (bool, error) {
	token := authorizationToken(c.GetHeader("Authorization"))
	if token == "" {
		return false, nil
	}
	if !provider.ValidateToken(token) {
		return false, nil
	}
	username, err := provider.GetUsernameFromToken(token)
	if err != nil {
		return false, err
	}
	roles, err := provider.ExtractRoles(token)
	if err != nil {
		return false, err
	}
	c.Set("username", username)
	c.Set("roles", roles)
	normalized := normalizeRoles(roles)
	c.Set("normalizedRoles", normalized)
	if len(normalized) > 0 {
		c.Set("role", normalized[0])
	}
	return true, nil
}

func authorizationToken(header string) string {
	header = strings.TrimSpace(header)
	if !strings.HasPrefix(header, "Bearer ") {
		return ""
	}
	return strings.TrimSpace(strings.TrimPrefix(header, "Bearer "))
}

func normalizeRoles(roles []string) []string {
	normalized := make([]string, 0, len(roles))
	for _, role := range roles {
		role = strings.TrimSpace(strings.TrimPrefix(role, "ROLE_"))
		if role != "" {
			normalized = append(normalized, role)
		}
	}
	return normalized
}

func hasAnyRole(c *gin.Context, allowed ...string) bool {
	allowedSet := map[string]bool{}
	for _, role := range allowed {
		allowedSet[strings.ToUpper(strings.TrimSpace(strings.TrimPrefix(role, "ROLE_")))] = true
	}
	if role := c.GetString("role"); allowedSet[strings.ToUpper(strings.TrimSpace(strings.TrimPrefix(role, "ROLE_")))] {
		return true
	}
	if roles, ok := c.Get("roles"); ok {
		if values, ok := roles.([]string); ok {
			for _, role := range values {
				if allowedSet[strings.ToUpper(strings.TrimSpace(strings.TrimPrefix(role, "ROLE_")))] {
					return true
				}
			}
		}
	}
	if roles, ok := c.Get("normalizedRoles"); ok {
		if values, ok := roles.([]string); ok {
			for _, role := range values {
				if allowedSet[strings.ToUpper(strings.TrimSpace(role))] {
					return true
				}
			}
		}
	}
	return false
}

func requiresAdmin(path string) bool {
	if path == "/api/users/me" || path == "/api/users/me/password" {
		return false
	}
	adminPrefixes := []string{
		"/api/auth/users",
		"/api/users",
		"/api/roles",
		"/api/loginLogs",
		"/api/operationLogs",
		"/api/systemLogs",
		"/api/systemSettings",
		"/api/backups",
	}
	for _, prefix := range adminPrefixes {
		if path == prefix || strings.HasPrefix(path, prefix+"/") {
			return true
		}
	}
	return false
}

func envOrDefault(name string, fallback string) string {
	if value := strings.TrimSpace(os.Getenv(name)); value != "" {
		return value
	}
	return fallback
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
