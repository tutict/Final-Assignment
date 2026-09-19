package app

import (
	gozerorag "final_assignment_backend_go/project/internal/gozero/rag"
	"final_assignment_backend_go/project/internal/handler"
	"final_assignment_backend_go/project/internal/repo"
	"final_assignment_backend_go/project/internal/service"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func RegisterHTTP(router *gin.Engine, gormDB *gorm.DB, userService *service.UserManagementService, authService *service.AuthWsService, ragRuntime *gozerorag.Runtime) {
	root := router.Group("")
	api := router.Group("/api")

	appealService := service.NewAppealManagementService(repo.NewAppealManagementRepo(gormDB))
	backupService := service.NewBackupRestoreService(repo.NewBackupRestoreRepo(gormDB))
	deductionService := service.NewDeductionInformationService(repo.NewDeductionInformationRepo(gormDB))
	driverService := service.NewDriverInformationService(repo.NewDriverInformationRepo(gormDB))
	fineService := service.NewFineInformationService(repo.NewFineInformationRepo(gormDB))
	loginLogService := service.NewLoginLogService(repo.NewLoginLogRepo(gormDB))
	offenseService := service.NewOffenseInformationService(repo.NewOffenseInformationRepo(gormDB))
	offenseTypeService := service.NewOffenseTypeDictService(repo.NewOffenseTypeDictRepo(gormDB))
	operationLogService := service.NewOperationLogService(repo.NewOperationLogRepo(gormDB))
	paymentService := service.NewPaymentRecordService(repo.NewPaymentRecordRepo(gormDB))
	permissionService := service.NewPermissionManagementService(repo.NewPermissionManagementRepo(gormDB))
	progressService := service.NewProgressItemService(repo.NewProgressItemRepo(gormDB))
	roleService := service.NewRoleManagementService(repo.NewRoleManagementRepo(gormDB))
	systemLogsService := service.NewSystemLogsService(repo.NewSystemLogsRepo(gormDB))
	systemSettingsService := service.NewSystemSettingsService(repo.NewSystemSettingsRepo(gormDB))
	vehicleService := service.NewVehicleService(repo.NewVehicleInformationRepo(gormDB))
	trafficService := service.NewTrafficViolationService(gormDB)
	workflowService := service.NewWorkflowService(gormDB, offenseService, paymentService)
	offenseDetailsService := service.NewOffenseDetailsViewService(gormDB)

	handler.NewUserManagementController(userService).RegisterRoutes(api)
	handler.NewBackupRestoreController(backupService).RegisterRoutes(router)
	handler.NewDeductionInformationController(deductionService).RegisterRoutes(router)
	handler.NewDriverInformationController(driverService, userService).RegisterRoutes(router)
	handler.NewLoginLogController(loginLogService).RegisterRoutes(router)
	handler.NewOffenseTypeController(offenseTypeService).RegisterRoutes(api)
	handler.NewPaymentRecordController(paymentService, authService).RegisterRoutes(api)
	handler.NewPermissionHandler(permissionService).RegisterRoutes(router)
	handler.NewProgressHandler(progressService).RegisterRoutes(router)
	handler.NewRoleManagementController(roleService).RegisterRoutes(router)
	handler.NewSystemLogsController(systemLogsService).RegisterRoutes(router)
	handler.NewSystemSettingsController(systemSettingsService).RegisterRoutes(router)
	handler.NewVehicleController(vehicleService).RegisterRoutes(router)
	handler.NewWorkflowController(workflowService).RegisterRoutes(api)
	handler.NewOffenseDetailsViewController(offenseDetailsService).RegisterRoutes(api)
	handler.RegisterRagAdminRoutes(router, ragRuntime)
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
	group.GET("/offense/:offenseId", controller.GetFinesByOffenseID)
	group.GET("/driver/:driverId", controller.GetFinesByDriverID)
	group.GET("/search/handler", controller.GetFinesByPayee)
	group.GET("/search/status", controller.SearchByPaymentStatus)
	group.GET("/search/date-range", controller.SearchByFineTimeRange)
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
	mount := func(prefix string) {
		group := router.Group(prefix)
		group.GET("/violation-types", controller.GetViolationTypeCounts)
		group.GET("/time-series", controller.GetTimeSeriesData)
		group.GET("/appeal-reasons", controller.GetAppealReasonCounts)
		group.GET("/fine-payment-status", controller.GetFinePaymentStatus)
		group.GET("/status", controller.GetFinePaymentStatus)
	}
	mount("/api/traffic-violations")
	mount("/api/violations")
}

