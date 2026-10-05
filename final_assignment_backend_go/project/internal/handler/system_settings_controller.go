package handler

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
)

// SystemSettingsController 负责系统设置相关 API
type SystemSettingsController struct {
	systemSettingsService SystemSettingsService
	Dicts                 DictSource
}

type DictSource interface {
	ListSysDicts() ([]domain.SysDict, error)
}

// NewSystemSettingsController 创建控制器实例
func NewSystemSettingsController(s SystemSettingsService) *SystemSettingsController {
	return &SystemSettingsController{systemSettingsService: s}
}

func (ctrl *SystemSettingsController) WithDicts(source DictSource) *SystemSettingsController {
	ctrl.Dicts = source
	return ctrl
}

// RegisterRoutes 注册所有路由
func (ctrl *SystemSettingsController) RegisterRoutes(r *gin.Engine) {
	ctrl.mountLegacySettings(r.Group("/api/systemSettings"))
	ctrl.mountRowSettings(r.Group("/api/system/settings"))
}

func (ctrl *SystemSettingsController) mountLegacySettings(group *gin.RouterGroup) {
	group.GET("", ctrl.GetSystemSettings)
	ctrl.mountSettingFields(group)
}

func (ctrl *SystemSettingsController) mountRowSettings(group *gin.RouterGroup) {
	group.GET("", ctrl.ListSysSettings)
	group.GET("/key/:settingKey", ctrl.GetSysSettingByKey)
	group.GET("/category/:category", ctrl.SearchSettingsByCategory)
	group.GET("/search/key/prefix", ctrl.SearchSettingsByKeyPrefix)
	group.GET("/search/key/fuzzy", ctrl.SearchSettingsByKeyFuzzy)
	group.GET("/search/type", ctrl.SearchSettingsByType)
	group.GET("/search/editable", ctrl.SearchSettingsByEditable)
	group.GET("/search/encrypted", ctrl.SearchSettingsByEncrypted)
	group.GET("/dicts/search/type", ctrl.SearchDictsByType)
	group.GET("/dicts/search/code", ctrl.SearchDictsByCode)
	group.GET("/dicts/search/label/prefix", ctrl.SearchDictsByLabelPrefix)
	group.GET("/dicts/search/label/fuzzy", ctrl.SearchDictsByLabelFuzzy)
	group.GET("/dicts/search/parent", ctrl.SearchDictsByParent)
	group.GET("/dicts/search/default", ctrl.SearchDictsByDefault)
	group.GET("/dicts/search/status", ctrl.SearchDictsByStatus)
	group.GET("/dicts", ctrl.ListDicts)
	group.GET("/dicts/:dictId", ctrl.GetDict)
	group.GET("/:settingId", ctrl.GetSysSettingByID)
	ctrl.mountSettingFields(group)
}

func (ctrl *SystemSettingsController) mountSettingFields(group *gin.RouterGroup) {
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

func (ctrl *SystemSettingsController) ListSysSettings(c *gin.Context) {
	rows, err := ctrl.systemSettingsService.ListSysSettings()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, rows)
}

func (ctrl *SystemSettingsController) GetSysSettingByID(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("settingId"))
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid setting id"})
		return
	}
	rows, err := ctrl.systemSettingsService.ListSysSettings()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	for _, row := range rows {
		if row.SettingID == id {
			c.JSON(http.StatusOK, row)
			return
		}
	}
	c.JSON(http.StatusNotFound, gin.H{"error": "setting not found"})
}

func (ctrl *SystemSettingsController) GetSysSettingByKey(c *gin.Context) {
	key := c.Param("settingKey")
	ctrl.searchSettings(c, func(row domain.SysSetting) bool {
		return strings.EqualFold(row.SettingKey, key)
	}, true)
}

func (ctrl *SystemSettingsController) SearchSettingsByCategory(c *gin.Context) {
	query := c.Param("category")
	ctrl.searchSettings(c, func(row domain.SysSetting) bool { return strings.EqualFold(row.Category, query) }, false)
}

func (ctrl *SystemSettingsController) SearchSettingsByKeyPrefix(c *gin.Context) {
	query := c.Query("settingKey")
	ctrl.searchSettings(c, func(row domain.SysSetting) bool { return hasPrefixFold(row.SettingKey, query) }, false)
}

func (ctrl *SystemSettingsController) SearchSettingsByKeyFuzzy(c *gin.Context) {
	query := c.Query("settingKey")
	ctrl.searchSettings(c, func(row domain.SysSetting) bool { return containsFold(row.SettingKey, query) }, false)
}

func (ctrl *SystemSettingsController) SearchSettingsByType(c *gin.Context) {
	query := c.Query("settingType")
	ctrl.searchSettings(c, func(row domain.SysSetting) bool { return strings.EqualFold(row.SettingType, query) }, false)
}

func (ctrl *SystemSettingsController) SearchSettingsByEditable(c *gin.Context) {
	want := strings.EqualFold(c.Query("isEditable"), "true")
	ctrl.searchSettings(c, func(row domain.SysSetting) bool { return row.IsEditable == want }, false)
}

func (ctrl *SystemSettingsController) SearchSettingsByEncrypted(c *gin.Context) {
	want := strings.EqualFold(c.Query("isEncrypted"), "true")
	ctrl.searchSettings(c, func(row domain.SysSetting) bool { return row.IsEncrypted == want }, false)
}

func (ctrl *SystemSettingsController) searchSettings(c *gin.Context, match func(domain.SysSetting) bool, single bool) {
	rows, err := ctrl.systemSettingsService.ListSysSettings()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	filtered := make([]domain.SysSetting, 0)
	for _, row := range rows {
		if match(row) {
			filtered = append(filtered, row)
		}
	}
	if single {
		if len(filtered) == 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "setting not found"})
			return
		}
		c.JSON(http.StatusOK, filtered[0])
		return
	}
	c.JSON(http.StatusOK, filtered)
}

func (ctrl *SystemSettingsController) ListDicts(c *gin.Context) {
	rows, err := ctrl.dicts()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, rows)
}

func (ctrl *SystemSettingsController) GetDict(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("dictId"))
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid dict id"})
		return
	}
	rows, err := ctrl.dicts()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	for _, row := range rows {
		if row.DictID == id {
			c.JSON(http.StatusOK, row)
			return
		}
	}
	c.JSON(http.StatusNotFound, gin.H{"error": "dict not found"})
}

func (ctrl *SystemSettingsController) SearchDictsByType(c *gin.Context) {
	query := c.Query("dictType")
	ctrl.searchDicts(c, func(row domain.SysDict) bool { return strings.EqualFold(row.DictType, query) })
}

func (ctrl *SystemSettingsController) SearchDictsByCode(c *gin.Context) {
	query := c.Query("dictCode")
	ctrl.searchDicts(c, func(row domain.SysDict) bool { return hasPrefixFold(row.DictCode, query) })
}

func (ctrl *SystemSettingsController) SearchDictsByLabelPrefix(c *gin.Context) {
	query := c.Query("dictLabel")
	ctrl.searchDicts(c, func(row domain.SysDict) bool { return hasPrefixFold(row.DictLabel, query) })
}

func (ctrl *SystemSettingsController) SearchDictsByLabelFuzzy(c *gin.Context) {
	query := c.Query("dictLabel")
	ctrl.searchDicts(c, func(row domain.SysDict) bool { return containsFold(row.DictLabel, query) })
}

func (ctrl *SystemSettingsController) SearchDictsByParent(c *gin.Context) {
	id, err := strconv.Atoi(c.Query("parentId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid parent id"})
		return
	}
	ctrl.searchDicts(c, func(row domain.SysDict) bool {
		return row.ParentID != nil && *row.ParentID == id
	})
}

func (ctrl *SystemSettingsController) SearchDictsByDefault(c *gin.Context) {
	want := strings.EqualFold(c.Query("isDefault"), "true")
	ctrl.searchDicts(c, func(row domain.SysDict) bool { return row.IsDefault == want })
}

func (ctrl *SystemSettingsController) SearchDictsByStatus(c *gin.Context) {
	query := c.Query("status")
	ctrl.searchDicts(c, func(row domain.SysDict) bool { return strings.EqualFold(row.Status, query) })
}

func (ctrl *SystemSettingsController) searchDicts(c *gin.Context, match func(domain.SysDict) bool) {
	rows, err := ctrl.dicts()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	filtered := make([]domain.SysDict, 0)
	for _, row := range rows {
		if match(row) {
			filtered = append(filtered, row)
		}
	}
	c.JSON(http.StatusOK, filtered)
}

func (ctrl *SystemSettingsController) dicts() ([]domain.SysDict, error) {
	if ctrl.Dicts == nil {
		return []domain.SysDict{}, nil
	}
	return ctrl.Dicts.ListSysDicts()
}
