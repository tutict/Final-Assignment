package main

import (
	"encoding/base64"
	"log"
	"net/http"
	"os"
	"strings"

	config "final_assignment_backend_go/project/configs"
	authcfg "final_assignment_backend_go/project/configs/auth"
	"final_assignment_backend_go/project/global_exception"
	"final_assignment_backend_go/project/internal/handler"
	"final_assignment_backend_go/project/internal/repo"
	"final_assignment_backend_go/project/internal/service"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func main() {
	db := config.InitDB()
	tokenProvider := initTokenProvider()

	userService := service.NewUserManagementService(repo.NewUserManagementRepo(db))
	authService := service.NewAuthWsService(userService, tokenProvider)
	authHandler := handler.NewAuthHandler(authService)

	router := gin.Default()
	router.Use(global_exception.GlobalExceptionHandler())
	router.Use(optionalPrincipal(tokenProvider))

	router.GET("/api/actuator/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "UP"})
	})
	router.POST("/api/auth/login", authHandler.Login)
	router.POST("/api/auth/register", authHandler.RegisterUser)
	router.POST("/api/auth/refresh", authHandler.Refresh)

	router.Use(requiredPrincipal(tokenProvider), accessPolicy())
	router.POST("/api/auth/logout", authHandler.Logout)
	router.GET("/api/auth/users", authHandler.GetAllUsers)
	registerRoutes(router, db, userService)

	addr := ":" + envOrDefault("PORT", "8080")
	log.Printf("Go backend listening on %s", addr)
	if err := router.Run(addr); err != nil {
		log.Fatalf("server stopped: %v", err)
	}
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
