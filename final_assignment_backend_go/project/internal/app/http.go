package app

import (
	gozerorag "final_assignment_backend_go/project/internal/gozero/rag"
	"final_assignment_backend_go/project/internal/handler"
	"final_assignment_backend_go/project/internal/repo"
	"final_assignment_backend_go/project/internal/service/admin"
	"final_assignment_backend_go/project/internal/service/appeal"
	"final_assignment_backend_go/project/internal/service/audit"
	authsvc "final_assignment_backend_go/project/internal/service/auth"
	"final_assignment_backend_go/project/internal/service/business"
	"final_assignment_backend_go/project/internal/service/driver"
	"final_assignment_backend_go/project/internal/service/offense"
	"final_assignment_backend_go/project/internal/service/payment"
	"final_assignment_backend_go/project/internal/service/statemachine"
	"final_assignment_backend_go/project/internal/service/system"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func RegisterHTTP(router *gin.Engine, gormDB *gorm.DB, userService *admin.UserManagementService, authService *authsvc.AuthWsService, ragRuntime *gozerorag.Runtime) {
	root := router.Group("")
	api := router.Group("/api")

	appealService := appeal.NewAppealManagementService(repo.NewAppealManagementRepo(gormDB))
	backupService := admin.NewBackupRestoreService(repo.NewBackupRestoreRepo(gormDB))
	deductionService := offense.NewDeductionInformationService(repo.NewDeductionInformationRepo(gormDB))
	driverService := driver.NewDriverInformationService(repo.NewDriverInformationRepo(gormDB))
	fineService := offense.NewFineInformationService(repo.NewFineInformationRepo(gormDB))
	loginLogService := audit.NewLoginLogService(repo.NewLoginLogRepo(gormDB))
	offenseService := offense.NewOffenseInformationService(repo.NewOffenseInformationRepo(gormDB))
	offenseTypeService := offense.NewOffenseTypeDictService(repo.NewOffenseTypeDictRepo(gormDB))
	operationLogService := audit.NewOperationLogService(repo.NewOperationLogRepo(gormDB))
	paymentService := payment.NewPaymentRecordService(repo.NewPaymentRecordRepo(gormDB))
	permissionService := admin.NewPermissionManagementService(repo.NewPermissionManagementRepo(gormDB))
	progressService := system.NewProgressItemService(repo.NewProgressItemRepo(gormDB))
	roleService := admin.NewRoleManagementService(repo.NewRoleManagementRepo(gormDB))
	systemLogsService := audit.NewSystemLogsService(repo.NewSystemLogsRepo(gormDB))
	systemSettingsService := admin.NewSystemSettingsService(repo.NewSystemSettingsRepo(gormDB))
	vehicleService := driver.NewVehicleService(repo.NewVehicleInformationRepo(gormDB))
	trafficService := business.NewTrafficViolationService(gormDB)
	workflowService := statemachine.NewWorkflowService(gormDB, offenseService, paymentService)
	offenseDetailsService := offense.NewOffenseDetailsViewService(gormDB)

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
