package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"
)

// SystemSettingsController 负责系统设置相关 API
type SystemSettingsController struct {
	systemSettingsService *service.SystemSettingsService
}

// NewSystemSettingsController 创建控制器实例
func NewSystemSettingsController(s *service.SystemSettingsService) *SystemSettingsController {
	return &SystemSettingsController{systemSettingsService: s}
}

// RegisterRoutes 注册所有路由
func (ctrl *SystemSettingsController) RegisterRoutes(r *gin.Engine) {
	group := r.Group("/api/systemSettings")

	// 权限控制可通过中间件实现
	group.GET("", ctrl.GetSystemSettings)
	group.PUT("", ctrl.UpdateSystemSettings)

	group.GET("/systemName", ctrl.GetSystemName)
	group.GET("/systemVersion", ctrl.GetSystemVersion)
	group.GET("/systemDescription", ctrl.GetSystemDescription)
	group.GET("/copyrightInfo", ctrl.GetCopyrightInfo)
	group.GET("/storagePath", ctrl.GetStoragePath)
	group.GET("/loginTimeout", ctrl.GetLoginTimeout)
	group.GET("/sessionTimeout", ctrl.GetSessionTimeout)
	group.GET("/dateFormat", ctrl.GetDateFormat)
	group.GET("/pageSize", ctrl.GetPageSize)
	group.GET("/smtpServer", ctrl.GetSmtpServer)
	group.GET("/emailAccount", ctrl.GetEmailAccount)
	group.GET("/emailPassword", ctrl.GetEmailPassword)
}

// GetSystemSettings 获取完整系统设置
func (ctrl *SystemSettingsController) GetSystemSettings(c *gin.Context) {
	settings, err := ctrl.systemSettingsService.GetSystemSettings()
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "System settings not found"})
		return
	}
	c.JSON(http.StatusOK, settings)
}

// UpdateSystemSettings 更新系统设置
func (ctrl *SystemSettingsController) UpdateSystemSettings(c *gin.Context) {
	var settings domain.SystemSettings
	idempotencyKey := c.Query("idempotencyKey")

	if err := c.ShouldBindJSON(&settings); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if idempotencyKey == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing idempotency key"})
		return
	}

	err := ctrl.systemSettingsService.CheckAndInsertIdempotency(idempotencyKey, &settings)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, settings)
}

// 以下为各项字段的独立查询接口

func (ctrl *SystemSettingsController) GetSystemName(c *gin.Context) {
	name := ctrl.systemSettingsService.GetSystemName()
	if name == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "System name not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"systemName": name})
}

func (ctrl *SystemSettingsController) GetSystemVersion(c *gin.Context) {
	version := ctrl.systemSettingsService.GetSystemVersion()
	if version == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "System version not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"systemVersion": version})
}

func (ctrl *SystemSettingsController) GetSystemDescription(c *gin.Context) {
	desc := ctrl.systemSettingsService.GetSystemDescription()
	if desc == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "System description not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"systemDescription": desc})
}

func (ctrl *SystemSettingsController) GetCopyrightInfo(c *gin.Context) {
	info := ctrl.systemSettingsService.GetCopyrightInfo()
	if info == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Copyright info not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"copyrightInfo": info})
}

func (ctrl *SystemSettingsController) GetStoragePath(c *gin.Context) {
	path := ctrl.systemSettingsService.GetStoragePath()
	if path == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Storage path not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"storagePath": path})
}

func (ctrl *SystemSettingsController) GetLoginTimeout(c *gin.Context) {
	timeout := ctrl.systemSettingsService.GetLoginTimeout()
	c.JSON(http.StatusOK, gin.H{"loginTimeout": timeout})
}

func (ctrl *SystemSettingsController) GetSessionTimeout(c *gin.Context) {
	timeout := ctrl.systemSettingsService.GetSessionTimeout()
	c.JSON(http.StatusOK, gin.H{"sessionTimeout": timeout})
}

func (ctrl *SystemSettingsController) GetDateFormat(c *gin.Context) {
	format := ctrl.systemSettingsService.GetDateFormat()
	if format == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Date format not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"dateFormat": format})
}

func (ctrl *SystemSettingsController) GetPageSize(c *gin.Context) {
	pageSize := ctrl.systemSettingsService.GetPageSize()
	c.JSON(http.StatusOK, gin.H{"pageSize": pageSize})
}

func (ctrl *SystemSettingsController) GetSmtpServer(c *gin.Context) {
	server := ctrl.systemSettingsService.GetSmtpServer()
	if server == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "SMTP server not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"smtpServer": server})
}

func (ctrl *SystemSettingsController) GetEmailAccount(c *gin.Context) {
	account := ctrl.systemSettingsService.GetEmailAccount()
	if account == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Email account not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"emailAccount": account})
}

func (ctrl *SystemSettingsController) GetEmailPassword(c *gin.Context) {
	password := ctrl.systemSettingsService.GetEmailPassword()
	if password == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Email password not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"emailPassword": password})
}
